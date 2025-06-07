import Foundation
import Security
import SwiftUI
import Combine
import LocalAuthentication

final class UserSession: ObservableObject {
    private let sessionKey = "com.vivamove.userSession"
    private let appleUserIdKey = "com.vivamove.appleUserId"
    private let keychainService = "com.vivamove.keychain"
    
    @Published private(set) var isLoggedIn = false
    @Published private(set) var userProfile: UserProfile? = nil
    var accessToken: String? = nil
    var refreshToken: String? = nil
    private var cancellables = Set<AnyCancellable>()
    
    // Add nonisolated to make the method callable from any isolation context
    nonisolated var userId: String? {
        return userProfile?.userSummary.id
    }

    init() {
        AppLogger.info("Creating user session", category: .auth)
        restoreSessionFromKeychain()
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        // User profile updated observer
        NotificationCenter.default.publisher(for: .userProfileUpdated)
            .compactMap { $0.object as? UserProfile }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedProfile in
                guard let self = self else { return }
                // Only update if this is the current user's profile
                if updatedProfile.userSummary.id == self.userId {
                    setUserProfile(updatedProfile)
                }
            }
            .store(in: &cancellables)
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
            "userProfileData": (try? JSONEncoder.vivaEncoder.encode(userProfile)) ?? Data()
        ]
        
        // Convert session data to Data
        guard let sessionDataEncoded = try? PropertyListSerialization.data(
            fromPropertyList: sessionData,
            format: .binary,
            options: 0) else {
            AppLogger.error("Error encoding session data", category: .auth)
            return
        }
        
        // Try to create access control for biometric authentication
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: sessionKey,
            kSecValueData as String: sessionDataEncoded
        ]
        
        // Check if biometric authentication is available
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // Biometrics available - use enhanced security
            let accessControl = SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                .biometryAny,
                nil
            )
            query[kSecAttrAccessControl as String] = accessControl
            AppLogger.info("Using biometric protection for session data", category: .auth)
        } else {
            // Biometrics not available - use basic security
            query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            AppLogger.info("Using basic keychain protection for session data (biometrics not available)", category: .auth)
        }
        
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
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: sessionKey,
            kSecReturnData as String: true
        ]
        
        // Add biometric authentication context for protected data
        let context = LAContext()
        context.localizedFallbackTitle = "Use Device Passcode"
        query[kSecUseAuthenticationContext as String] = context
        
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
    
    // MARK: - Apple User ID Keychain Storage
    
    func storeAppleUserId(_ userId: String) {
        guard let userIdData = userId.data(using: .utf8) else {
            AppLogger.error("Error encoding Apple user ID", category: .auth)
            return
        }
        
        // Use basic security for Apple user ID (non-sensitive identifier)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: appleUserIdKey,
            kSecValueData as String: userIdData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // First try to delete any existing Apple user ID
        SecItemDelete(query as CFDictionary)
        
        // Then save the new Apple user ID
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            AppLogger.error("Error saving Apple user ID to Keychain: \(status)", category: .auth)
            return
        }
        
        AppLogger.info("Apple user ID stored securely in Keychain", category: .auth)
    }
    
    func getAppleUserId() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: appleUserIdKey,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            AppLogger.info("No Apple user ID found in keychain: \(status)", category: .auth)
            return nil
        }
        
        guard let userIdData = result as? Data,
              let userId = String(data: userIdData, encoding: .utf8) else {
            AppLogger.warning("Invalid Apple user ID data in keychain", category: .auth)
            return nil
        }
        
        return userId
    }
    
    func deleteAppleUserId() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: appleUserIdKey
        ]
        
        SecItemDelete(query as CFDictionary)
        AppLogger.info("Apple user ID removed from Keychain", category: .auth)
    }
}
