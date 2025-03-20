import Foundation
import Security
import SwiftUI

final class UserSession: ObservableObject {
    private let sessionKey = "com.vivamove.userSession"
    private let keychainService = "com.vivamove.keychain"
    
    @Published private(set) var isLoggedIn = false
    @Published private(set) var userProfile: UserProfile? = nil
    var accessToken: String? = nil
    var refreshToken: String? = nil
    
    // Add nonisolated to make the method callable from any isolation context
    nonisolated var userId: String? {
        return userProfile?.id
    }

    init() {
        AppLogger.info("Creating user session", category: .auth)
        restoreSessionFromKeychain()
    }
    
    func setUserProfile(_ userProfile: UserProfile) {
        self.userProfile = userProfile
        saveSessionToKeychain()
    }

    func setTestLoggedIn() async {
        await MainActor.run {
            self.isLoggedIn = true
        }
    }
    
    func setLoggedIn(userProfile: UserProfile, accessToken: String, refreshToken: String) {
        withAnimation(.easeInOut(duration: 0.5)) {
            self.userProfile = userProfile
            self.accessToken = accessToken
            self.refreshToken = refreshToken
            self.isLoggedIn = true
        }
        
        // Save entire session to keychain
        saveSessionToKeychain()
    }
    
    func updateTokens(accessToken: String, refreshToken: String? = nil) {
        self.accessToken = accessToken
        if let refreshToken = refreshToken {
            self.refreshToken = refreshToken
        }
        saveSessionToKeychain()
    }
    
    func setLoggedOut() async {
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.5)) {
                self.isLoggedIn = false
            } completion: {
                self.userProfile = nil
                self.accessToken = nil
                self.refreshToken = nil
                self.deleteSessionFromKeychain()
            }
        }
    }
    
    // MARK: - Keychain Operations
    
    private func saveSessionToKeychain() {
        guard let userProfile = userProfile else { return }
        
        // Create a dictionary to store all session data
        let sessionData: [String: Any] = [
            "sessionToken": accessToken ?? "",
            "refreshToken": refreshToken ?? "",
            "isLoggedIn": isLoggedIn,
            "userProfileData": (try? JSONEncoder().encode(userProfile)) ?? Data()
        ]
        
        // Convert session data to Data
        guard let sessionDataEncoded = try? PropertyListSerialization.data(
            fromPropertyList: sessionData,
            format: .binary,
            options: 0) else {
            AppLogger.error("Error encoding session data", category: .auth)
            return
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: sessionKey,
            kSecValueData as String: sessionDataEncoded
        ]
        
        // First try to delete any existing session
        SecItemDelete(query as CFDictionary)
        
        // Then save the new session
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            AppLogger.error("Error saving session to Keychain: \(status)", category: .auth)
            return
        }
    }
    
    private func restoreSessionFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: sessionKey,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status != errSecSuccess {
            AppLogger.info("No session found in keychain: \(status)", category: .auth)
            return
        }
        
        guard let sessionData = result as? Data else {
            AppLogger.warning("No session data found in keychain", category: .auth)
            return
        }
        
        // Decode the session data using PropertyListSerialization instead
        guard let sessionDict = try? PropertyListSerialization.propertyList(
            from: sessionData,
            options: [],
            format: nil) as? [String: Any] else {
            AppLogger.error("Error decoding session data", category: .auth)
            return
        }
        
        // Extract user profile data
        guard let userProfileData = sessionDict["userProfileData"] as? Data,
              let userProfile = try? JSONDecoder().decode(UserProfile.self, from: userProfileData) else {
            AppLogger.error("Error decoding user profile data", category: .auth)
            return
        }
        
        self.userProfile = userProfile
        self.accessToken = sessionDict["sessionToken"] as? String
        self.refreshToken = sessionDict["refreshToken"] as? String
        
        if let isLoggedIn = sessionDict["isLoggedIn"] as? Bool, isLoggedIn {
            self.isLoggedIn = true
        }
    }
    
    private func deleteSessionFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: sessionKey
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
