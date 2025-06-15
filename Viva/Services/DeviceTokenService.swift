import Foundation
import UIKit

class DeviceTokenService {
    private let networkClient: NetworkClient<VivaErrorResponse>
    private let userSession: UserSession
    
    init(networkClient: NetworkClient<VivaErrorResponse>, userSession: UserSession) {
        self.networkClient = networkClient
        self.userSession = userSession
    }
    
    /// Registers a new device token with the backend
    /// - Parameter deviceTokenRequest: The device token request containing APNS and FCM tokens
    /// - Returns: Success or failure
    func registerDeviceToken(_ deviceTokenRequest: DeviceTokenRequest) async throws {
        AppLogger.info("Registering device tokens for platform: \(deviceTokenRequest.platform)", category: .network)
        
        guard deviceTokenRequest.isValid else {
            throw DeviceTokenError.invalidRequest("Device token request validation failed")
        }
        
        guard userSession.isLoggedIn else {
            throw DeviceTokenError.notAuthenticated("User must be logged in to register device token")
        }
        
        try await networkClient.post(
            path: "/device-tokens",
            body: deviceTokenRequest
        )
        AppLogger.info("Successfully registered device tokens", category: .network)
    }
    
    /// Updates an existing device token
    /// - Parameters:
    ///   - notificationToken: The FCM token identifier to update
    ///   - deviceTokenRequest: The updated device token request
    /// - Returns: Success or failure
    func updateDeviceToken(_ notificationToken: String, with deviceTokenRequest: DeviceTokenRequest) async throws {
        AppLogger.info("Updating device token: \(notificationToken.prefix(8))...", category: .network)
        
        guard deviceTokenRequest.isValid else {
            throw DeviceTokenError.invalidRequest("Device token request validation failed")
        }
        
        guard userSession.isLoggedIn else {
            throw DeviceTokenError.notAuthenticated("User must be logged in to update device token")
        }
        
        try await networkClient.put(
            path: "/device-tokens/\(notificationToken)",
            body: deviceTokenRequest
        )
        AppLogger.info("Successfully updated device tokens", category: .network)
    }
    
    /// Deletes a device token from the backend
    /// - Parameter notificationToken: The FCM token identifier to delete
    /// - Returns: Success or failure
    func deleteDeviceToken(_ notificationToken: String) async throws {
        AppLogger.info("Deleting device token: \(notificationToken.prefix(8))...", category: .network)
        
        guard !notificationToken.isEmpty else {
            throw DeviceTokenError.invalidRequest("FCM token cannot be empty")
        }
        
        // Note: We allow deletion even if not logged in to handle logout cleanup
        
        try await networkClient.delete(
            path: "/device-tokens/\(notificationToken)"
        )
        AppLogger.info("Successfully deleted device token", category: .network)
    }
    
    /// Registers or updates a device token based on whether it's already registered
    /// - Parameter deviceTokenRequest: The device token request
    /// - Parameter existingNotificationToken: The previously registered FCM token, if any
    /// - Returns: Success or failure
    func registerOrUpdateDeviceToken(_ deviceTokenRequest: DeviceTokenRequest, existingNotificationToken: String? = nil) async throws {
        if let existingNotificationToken = existingNotificationToken {
            // Update existing token
            try await updateDeviceToken(existingNotificationToken, with: deviceTokenRequest)
        } else {
            // Register new token
            try await registerDeviceToken(deviceTokenRequest)
        }
    }
}

// MARK: - Device Token Management

extension DeviceTokenService {
    /// Manages the complete device token lifecycle for the current user
    /// - Parameters:
    ///   - apnsToken: The APNS token to register
    ///   - fcmToken: The FCM token to register
    /// - Returns: Success or failure
    func manageDeviceTokens(apnsToken: String, fcmToken: String) async throws {
        let deviceTokenRequest = DeviceTokenRequest.ios(
            deviceToken: apnsToken,
            notificationToken: fcmToken
        )
        
        // Get previously stored FCM token
        let existingFCMToken = getStoredFCMToken()
        
        // Always register/update since tokens can change independently
        AppLogger.info("Managing device tokens (APNS and FCM)", category: .network)
        
        // If we had an old FCM token and it's different, delete it first
        if let oldFCMToken = existingFCMToken, oldFCMToken != fcmToken {
            do {
                try await deleteDeviceToken(oldFCMToken)
            } catch {
                AppLogger.warning("Failed to delete old device token: \(error)", category: .network)
                // Continue anyway, as the new registration is more important
            }
        }
        
        // Register the new tokens
        try await registerDeviceToken(deviceTokenRequest)
        
        // Store both tokens
        storeAPNSToken(apnsToken)
        storeFCMToken(fcmToken)
    }
    
    /// Cleans up device tokens on logout
    func cleanupDeviceTokens() async {
        guard let fcmToken = getStoredFCMToken() else {
            AppLogger.info("No FCM token to cleanup", category: .network)
            return
        }
        
        do {
            try await deleteDeviceToken(fcmToken)
            clearStoredTokens()
            AppLogger.info("Successfully cleaned up device tokens on logout", category: .network)
        } catch {
            AppLogger.error("Failed to cleanup device tokens on logout: \(error)", category: .network)
            // Still clear local storage even if backend deletion failed
            clearStoredTokens()
        }
    }
}

// MARK: - Token Storage

private extension DeviceTokenService {
    private static let apnsTokenKey = "stored_apns_device_token"
    private static let fcmTokenKey = "stored_fcm_device_token"
    
    /// Stores APNS token securely in Keychain
    func storeAPNSToken(_ token: String) {
        do {
            try userSession.storeInKeychain(key: Self.apnsTokenKey, value: token)
            AppLogger.info("APNS token stored securely", category: .network)
        } catch {
            AppLogger.error("Failed to store APNS token: \(error)", category: .network)
        }
    }
    
    /// Stores FCM token securely in Keychain
    func storeFCMToken(_ token: String) {
        do {
            try userSession.storeInKeychain(key: Self.fcmTokenKey, value: token)
            AppLogger.info("FCM token stored securely", category: .network)
        } catch {
            AppLogger.error("Failed to store FCM token: \(error)", category: .network)
        }
    }
    
    /// Retrieves stored APNS token from Keychain
    func getStoredAPNSToken() -> String? {
        do {
            return try userSession.getFromKeychain(key: Self.apnsTokenKey)
        } catch {
            AppLogger.warning("Failed to retrieve stored APNS token: \(error)", category: .network)
            return nil
        }
    }
    
    /// Retrieves stored FCM token from Keychain
    func getStoredFCMToken() -> String? {
        do {
            return try userSession.getFromKeychain(key: Self.fcmTokenKey)
        } catch {
            AppLogger.warning("Failed to retrieve stored FCM token: \(error)", category: .network)
            return nil
        }
    }
    
    /// Clears both stored tokens from Keychain
    func clearStoredTokens() {
        do {
            try userSession.deleteFromKeychain(key: Self.apnsTokenKey)
            try userSession.deleteFromKeychain(key: Self.fcmTokenKey)
            AppLogger.info("Cleared stored tokens", category: .network)
        } catch {
            AppLogger.warning("Failed to clear stored tokens: \(error)", category: .network)
        }
    }
}

// MARK: - Error Types

enum DeviceTokenError: LocalizedError {
    case invalidRequest(String)
    case notAuthenticated(String)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidRequest(let message):
            return "Invalid device token request: \(message)"
        case .notAuthenticated(let message):
            return "Authentication required: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

