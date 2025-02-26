import Foundation
import Security
import SwiftUI

final class UserSession: ObservableObject {
    private let tokenKey = "com.vivamove.accessToken"
    private let keychainService = "com.vivamove.keychain"
    
    @Published private(set) var isLoggedIn = false
    @Published private(set) var userProfile: UserProfile? = nil

    var userId: String {
        return userProfile!.id
    }
    
    func getAccessToken() -> String? {
        return retrieveToken()
    }
    
    func setAccessToken(_ sessionToken: String) {
        saveToken(sessionToken)
    }
    
    func getUserProfile() -> UserProfile {
        return userProfile!
    }

    func getUserId() -> String {
        return userProfile!.id
    }

    func setUserProfile(_ userProfile: UserProfile) {
        return self.userProfile = userProfile
    }

    func setTestLoggedIn() async {
        await MainActor.run {
            self.isLoggedIn = true
        }
    }
    
    func setLoggedIn(_ userProfile: UserProfile) {
        self.userProfile = userProfile
        withAnimation(.easeInOut(duration: 0.5)) {
            self.isLoggedIn = true
        }
    }
    
    func setLoggedOut()  {
        withAnimation(.easeInOut(duration: 0.5)) {
            self.isLoggedIn = false;
        } completion: {
            self.userProfile = nil
            self.deleteToken()
        }
    }

    private func saveToken(_ token: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: tokenKey,
            kSecValueData as String: token.data(using: .utf8)!
        ]
        
        // First try to delete any existing token
        SecItemDelete(query as CFDictionary)
        
        // Then save the new token
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            print("Error saving token to Keychain: \(status)")
            return
        }
    }
    
    private func retrieveToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: tokenKey,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let tokenData = result as? Data,
              let token = String(data: tokenData, encoding: .utf8)
        else {
            return nil
        }
        
        return token
    }
    
    private func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: tokenKey
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
