import Foundation
import Security
import SwiftUI

final class UserSession: ObservableObject {
    private let sessionKey = "com.vivamove.userSession"
    private let keychainService = "com.vivamove.keychain"
    
    @Published private(set) var isLoggedIn = false
    @Published private(set) var userProfile: UserProfile? = nil
    private var sessionToken: String? = nil

    init() {
        print("Creating user session")
        // Try to restore session from keychain on initialization
        restoreSessionFromKeychain()
    }
    
    var userId: String {
        return userProfile!.id
    }

    func getUserProfile() -> UserProfile {
        return userProfile!
    }

    func getAccessToken() -> String? {
        return sessionToken
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
    
    func setLoggedIn(userProfile: UserProfile, sessionToken: String) {
        withAnimation(.easeInOut(duration: 0.5)) {
            self.userProfile = userProfile
            self.sessionToken = sessionToken
            self.isLoggedIn = true
        }
        
        // Save entire session to keychain
        saveSessionToKeychain()
    }
    
    func setLoggedOut()  {
        withAnimation(.easeInOut(duration: 0.5)) {
            self.isLoggedIn = false;
        } completion: {
            self.userProfile = nil
            self.sessionToken = nil
            self.deleteSessionFromKeychain()
        }
    }

    // MARK: - Keychain Operations
    
    private func saveSessionToKeychain() {
        guard let userProfile = userProfile else { return }
        
        // Create a dictionary to store all session data
        let sessionData: [String: Any] = [
            "sessionToken": sessionToken ?? "",
            "isLoggedIn": isLoggedIn,
            "userProfileData": (try? JSONEncoder().encode(userProfile)) ?? Data()
        ]
        
        // Convert session data to Data
        guard let sessionDataEncoded = try? PropertyListSerialization.data(
            fromPropertyList: sessionData,
            format: .binary,
            options: 0) else {
            print("Error encoding session data")
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
            print("Error saving session to Keychain: \(status)")
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
            print("No session found in keychain: \(status)")
            return
        }
        
        guard let sessionData = result as? Data else {
            print("No session data found in keychain")
            return
        }
        
        // Decode the session data using PropertyListSerialization instead
        guard let sessionDict = try? PropertyListSerialization.propertyList(
            from: sessionData,
            options: [],
            format: nil) as? [String: Any] else {
            print("Error decoding session data")
            return
        }
        
        // Extract user profile data
        guard let userProfileData = sessionDict["userProfileData"] as? Data,
              let userProfile = try? JSONDecoder().decode(UserProfile.self, from: userProfileData) else {
            print("Error decoding user profile data")
            return
        }
        
        self.userProfile = userProfile
        self.sessionToken = sessionDict["sessionToken"] as? String
        
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
