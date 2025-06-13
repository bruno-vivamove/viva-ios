import Foundation
import UIKit
import UserNotifications
import FirebaseMessaging

// MARK: - Notification Service

/// Handles all push notification related functionality including FCM token management,
/// notification registration, and background notification processing
class NotificationService: ObservableObject {
    
    // MARK: - Properties
    
    private let userSession: UserSession
    private let deviceTokenService: DeviceTokenService
    private let backgroundHealthSyncManager: BackgroundHealthSyncManager
    private let backgroundMatchupRefreshManager: BackgroundMatchupRefreshManager
    
    // MARK: - Initialization
    
    init(
        userSession: UserSession,
        deviceTokenService: DeviceTokenService,
        backgroundHealthSyncManager: BackgroundHealthSyncManager,
        backgroundMatchupRefreshManager: BackgroundMatchupRefreshManager
    ) {
        self.userSession = userSession
        self.deviceTokenService = deviceTokenService
        self.backgroundHealthSyncManager = backgroundHealthSyncManager
        self.backgroundMatchupRefreshManager = backgroundMatchupRefreshManager
    }
    
    // MARK: - Push Notification Registration
    
    /// Registers the app for push notifications
    func registerForPushNotifications() {
        AppLogger.info("Starting push notification registration", category: .network)
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            AppLogger.info("Current notification status: \(settings.authorizationStatus.rawValue)", category: .network)
            
            switch settings.authorizationStatus {
            case .notDetermined:
                self.requestNotificationPermission()
            case .denied:
                AppLogger.warning("Push notifications denied by user", category: .network)
            case .authorized, .provisional, .ephemeral:
                self.registerForRemoteNotifications()
            @unknown default:
                AppLogger.warning("Unknown notification status: \(settings.authorizationStatus.rawValue)", category: .network)
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                AppLogger.error("Notification permission error: \(error)", category: .network)
                return
            }
            
            AppLogger.info("Notification permission granted: \(granted)", category: .network)
            
            if granted {
                self.registerForRemoteNotifications()
            }
        }
    }
    
    private func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    // MARK: - Token Management
    
    /// Handles successful APNS token registration
    func handleAPNSTokenRegistration(_ deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        AppLogger.info("APNS token registered: \(tokenString)", category: .network)
        
        // Store device token locally
        UserDefaults.standard.set(tokenString, forKey: "deviceToken")
        
        // Set APNS token for Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken
    }
    
    /// Handles APNS token registration failure
    func handleAPNSTokenRegistrationFailure(_ error: Error) {
        AppLogger.error("Failed to register for remote notifications: \(error)", category: .network)
    }
    
    /// Handles FCM token refresh
    func handleFCMTokenRefresh(_ fcmToken: String) {
        AppLogger.info("FCM token received/refreshed", category: .network)
        
        // Store FCM token locally
        UserDefaults.standard.set(fcmToken, forKey: "currentFCMToken")
        
        // Register with backend if user is logged in
        registerTokenWithBackend(fcmToken)
    }
    
    private func registerTokenWithBackend(_ fcmToken: String) {
        guard userSession.isLoggedIn else {
            AppLogger.info("User not logged in, skipping token registration", category: .network)
            return
        }
        
        Task {
            do {
                try await deviceTokenService.manageDeviceToken(fcmToken: fcmToken)
                AppLogger.info("Successfully registered FCM token with backend", category: .network)
            } catch {
                AppLogger.error("Failed to register FCM token: \(error)", category: .network)
            }
        }
    }
    
    // MARK: - Notification Processing
    
    /// Processes incoming notification data and routes to appropriate handlers
    func processNotification(_ userInfo: [AnyHashable: Any], completion: ((UIBackgroundFetchResult) -> Void)? = nil) {
        AppLogger.info("Processing notification", category: .network)
        
        // Notify Firebase Analytics
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Extract notification data
        guard let notificationData = extractNotificationData(from: userInfo) else {
            AppLogger.warning("Could not extract notification data", category: .network)
            completion?(.noData)
            return
        }
        
        // Route to appropriate handler
        routeNotification(action: notificationData.action, userId: notificationData.userId, completion: completion)
        
        // Post UI notification
        postUINotification(for: notificationData.action)
    }
    
    private func extractNotificationData(from userInfo: [AnyHashable: Any]) -> NotificationData? {
        if let customDataString = userInfo["custom_data"] as? String,
           let jsonData = customDataString.data(using: .utf8),
           let parsedData = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
           let action = parsedData["action"] as? String,
           let userId = parsedData["userId"] as? String {
            return NotificationData(action: action, userId: userId)
        }
        
        return nil
    }
    
    private func routeNotification(action: String, userId: String, completion: ((UIBackgroundFetchResult) -> Void)?) {
        switch action {
        case "sync_health_data":
            performHealthSync(for: userId, completion: completion)
        case "refresh_matchup":
            performMatchupRefresh(for: userId, completion: completion)
        default:
            AppLogger.warning("Unknown notification action: \(action)", category: .network)
            completion?(.noData)
        }
    }
    
    private func performHealthSync(for userId: String, completion: ((UIBackgroundFetchResult) -> Void)?) {
        AppLogger.info("Processing health data sync for user: \(userId)", category: .data)
        
        backgroundHealthSyncManager.performBackgroundHealthSync(for: userId) { success in
            DispatchQueue.main.async {
                completion?(success ? .newData : .failed)
            }
        }
    }
    
    private func performMatchupRefresh(matchupId: String, completion: ((UIBackgroundFetchResult) -> Void)?) {
        AppLogger.info("Processing matchup refresh for matchup: \(matchupId)", category: .data)
        
        backgroundMatchupRefreshManager.performBackgroundMatchupRefresh(for: userId) { success in
            DispatchQueue.main.async {
                completion?(success ? .newData : .failed)
            }
        }
    }
    
    private func postUINotification(for action: String) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .pushNotificationReceived,
                object: nil,
                userInfo: ["message": "Processing \(action)"]
            )
        }
    }
}

// MARK: - Supporting Types

private struct NotificationData {
    let action: String
    let userId: String
}
