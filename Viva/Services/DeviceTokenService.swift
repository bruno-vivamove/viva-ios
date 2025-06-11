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
    /// - Parameter deviceTokenRequest: The device token request containing token and platform info
    /// - Returns: Success or failure
    func registerDeviceToken(_ deviceTokenRequest: DeviceTokenRequest) async throws {
        AppLogger.info("Registering device token for platform: \(deviceTokenRequest.platform)", category: .network)
        
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
        AppLogger.info("Successfully registered device token", category: .network)
    }
    
    /// Updates an existing device token
    /// - Parameters:
    ///   - deviceToken: The current device token to update
    ///   - deviceTokenRequest: The updated device token request
    /// - Returns: Success or failure
    func updateDeviceToken(_ deviceToken: String, with deviceTokenRequest: DeviceTokenRequest) async throws {
        AppLogger.info("Updating device token: \(deviceToken.prefix(8))...", category: .network)
        
        guard deviceTokenRequest.isValid else {
            throw DeviceTokenError.invalidRequest("Device token request validation failed")
        }
        
        guard userSession.isLoggedIn else {
            throw DeviceTokenError.notAuthenticated("User must be logged in to update device token")
        }
        
        try await networkClient.put(
            path: "/device-tokens/\(deviceToken)",
            body: deviceTokenRequest
        )
        AppLogger.info("Successfully updated device token", category: .network)
    }
    
    /// Deletes a device token from the backend
    /// - Parameter deviceToken: The device token to delete
    /// - Returns: Success or failure
    func deleteDeviceToken(_ deviceToken: String) async throws {
        AppLogger.info("Deleting device token: \(deviceToken.prefix(8))...", category: .network)
        
        guard !deviceToken.isEmpty else {
            throw DeviceTokenError.invalidRequest("Device token cannot be empty")
        }
        
        // Note: We allow deletion even if not logged in to handle logout cleanup
        
        try await networkClient.delete(
            path: "/device-tokens/\(deviceToken)"
        )
        AppLogger.info("Successfully deleted device token", category: .network)
    }
    
    /// Registers or updates a device token based on whether it's already registered
    /// - Parameter deviceTokenRequest: The device token request
    /// - Parameter existingToken: The previously registered token, if any
    /// - Returns: Success or failure
    func registerOrUpdateDeviceToken(_ deviceTokenRequest: DeviceTokenRequest, existingToken: String? = nil) async throws {
        if let existingToken = existingToken {
            // Update existing token
            try await updateDeviceToken(existingToken, with: deviceTokenRequest)
        } else {
            // Register new token
            try await registerDeviceToken(deviceTokenRequest)
        }
    }
}

// MARK: - Device Token Management

extension DeviceTokenService {
    /// Manages the complete device token lifecycle for the current user
    /// - Parameter fcmToken: The FCM token to register
    /// - Returns: Success or failure
    func manageDeviceToken(fcmToken: String) async throws {
        let deviceTokenRequest = DeviceTokenRequest.ios(deviceToken: fcmToken)
        
        // Get previously stored token
        let existingToken = getStoredDeviceToken()
        
        if existingToken != fcmToken {
            // Token has changed, need to update
            AppLogger.info("Device token changed, updating registration", category: .network)
            
            // If we had an old token, delete it first
            if let oldToken = existingToken {
                do {
                    try await deleteDeviceToken(oldToken)
                } catch {
                    AppLogger.warning("Failed to delete old device token: \(error)", category: .network)
                    // Continue anyway, as the new registration is more important
                }
            }
            
            // Register the new token
            try await registerDeviceToken(deviceTokenRequest)
            
            // Store the new token
            storeDeviceToken(fcmToken)
        } else {
            AppLogger.info("Device token unchanged, skipping registration", category: .network)
        }
    }
    
    /// Cleans up device token on logout
    func cleanupDeviceToken() async {
        guard let deviceToken = getStoredDeviceToken() else {
            AppLogger.info("No device token to cleanup", category: .network)
            return
        }
        
        do {
            try await deleteDeviceToken(deviceToken)
            clearStoredDeviceToken()
            AppLogger.info("Successfully cleaned up device token on logout", category: .network)
        } catch {
            AppLogger.error("Failed to cleanup device token on logout: \(error)", category: .network)
            // Still clear local storage even if backend deletion failed
            clearStoredDeviceToken()
        }
    }
}

// MARK: - Token Storage

private extension DeviceTokenService {
    private static let deviceTokenKey = "stored_fcm_device_token"
    
    /// Stores device token securely in Keychain
    func storeDeviceToken(_ token: String) {
        do {
            try userSession.storeInKeychain(key: Self.deviceTokenKey, value: token)
            AppLogger.info("Device token stored securely", category: .network)
        } catch {
            AppLogger.error("Failed to store device token: \(error)", category: .network)
        }
    }
    
    /// Retrieves stored device token from Keychain
    func getStoredDeviceToken() -> String? {
        do {
            return try userSession.getFromKeychain(key: Self.deviceTokenKey)
        } catch {
            AppLogger.warning("Failed to retrieve stored device token: \(error)", category: .network)
            return nil
        }
    }
    
    /// Clears stored device token from Keychain
    func clearStoredDeviceToken() {
        do {
            try userSession.deleteFromKeychain(key: Self.deviceTokenKey)
            AppLogger.info("Cleared stored device token", category: .network)
        } catch {
            AppLogger.warning("Failed to clear stored device token: \(error)", category: .network)
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

