import FirebaseMessaging
import Foundation
import UIKit
import UserNotifications

// MARK: - Notification Service

/// Handles all push notification related functionality including FCM token management,
/// notification registration, and background notification processing
class NotificationService: ObservableObject {

    // MARK: - Properties

    private let userSession: UserSession
    private let deviceTokenService: DeviceTokenService
    private let backgroundHealthSyncManager: BackgroundHealthSyncManager
    private let backgroundMatchupRefreshManager: BackgroundMatchupRefreshManager
    
    // Current session tokens
    private var currentAPNSToken: String?
    private var currentFCMToken: String?

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

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [
            .alert, .sound, .badge,
        ]) { granted, error in
            if let error = error {
                AppLogger.error(
                    "Notification permission error: \(error)",
                    category: .network
                )
                return
            }

            AppLogger.info(
                "Notification permission granted: \(granted)",
                category: .network
            )

            if granted {
                self.registerForRemoteNotifications()
            }
        }
    }

    /// Registers the app for push notifications
    func registerForPushNotifications() {
        AppLogger.info(
            "Starting push notification registration",
            category: .network
        )

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            AppLogger.info(
                "Current notification status: \(settings.authorizationStatus.rawValue)",
                category: .network
            )

            switch settings.authorizationStatus {
            case .notDetermined:
                self.requestNotificationPermission()
            case .denied:
                AppLogger.warning(
                    "Push notifications denied by user",
                    category: .network
                )
            case .authorized, .provisional, .ephemeral:
                self.registerForRemoteNotifications()
            @unknown default:
                AppLogger.warning(
                    "Unknown notification status: \(settings.authorizationStatus.rawValue)",
                    category: .network
                )
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
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }
            .joined()
        AppLogger.info(
            "APNS token registered: \(tokenString)",
            category: .network
        )

        // Store current session token
        currentAPNSToken = tokenString
        
        // Store APNS token locally for persistence
        UserDefaults.standard.set(tokenString, forKey: "apnsToken")

        // Set APNS token for Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken
        
        // Try to register tokens (in case FCM token arrived first)
        tryRegisterTokensWithBackend()
    }

    /// Handles APNS token registration failure
    func handleAPNSTokenRegistrationFailure(_ error: Error) {
        AppLogger.error(
            "Failed to register for remote notifications: \(error)",
            category: .network
        )
    }

    /// Handles FCM token refresh
    func handleFCMTokenRefresh(_ fcmToken: String) {
        AppLogger.info("FCM token received/refreshed: \(fcmToken)", category: .network)

        // Store current session token
        currentFCMToken = fcmToken
        
        // Store FCM token locally for persistence
        UserDefaults.standard.set(fcmToken, forKey: "fcmToken")

        // Register both tokens with backend now that we have FCM token
        tryRegisterTokensWithBackend()
    }

    private func tryRegisterTokensWithBackend() {
        guard userSession.isLoggedIn else {
            AppLogger.info(
                "User not logged in, skipping token registration",
                category: .network
            )
            return
        }
        
        guard let apnsToken = currentAPNSToken,
              let fcmToken = currentFCMToken else {
            AppLogger.info(
                "Both APNS and FCM tokens not available yet in current session, waiting...",
                category: .network
            )
            return
        }

        Task {
            do {
                try await deviceTokenService.manageDeviceTokens(
                    apnsToken: apnsToken,
                    fcmToken: fcmToken
                )
                AppLogger.info(
                    "Successfully registered both tokens with backend",
                    category: .network
                )
            } catch {
                AppLogger.error(
                    "Failed to register tokens: \(error)",
                    category: .network
                )
            }
        }
    }

    // MARK: - Notification Processing

    /// Processes incoming notification data and routes to appropriate handlers
    func processNotification(
        _ userInfo: [AnyHashable: Any],
        completion: ((UIBackgroundFetchResult) -> Void)? = nil
    ) {
        // Notify Firebase Analytics
        Messaging.messaging().appDidReceiveMessage(userInfo)

        // Extract notification data
        guard let notificationData = extractNotificationData(from: userInfo)
        else {
            AppLogger.warning(
                "Could not extract notification data",
                category: .network
            )
            completion?(.noData)
            return
        }

        AppLogger.info(
            "Processing notification - Action: \(notificationData.action), UserId: \(notificationData.userId), MatchupIds: \(notificationData.matchupIds?.joined(separator: ", ") ?? "none")",
            category: .network
        )

        // Route to appropriate handler
        routeNotification(
            action: notificationData.action,
            userId: notificationData.userId,
            matchupIds: notificationData.matchupIds,
            completion: completion
        )

        // Post UI notification
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .pushNotificationReceived,
                object: nil,
                userInfo: ["message": "Processing \(notificationData.action)"]
            )
        }
    }

    private func extractNotificationData(from userInfo: [AnyHashable: Any])
        -> NotificationData?
    {
        if let customDataString = userInfo["custom_data"] as? String,
            let jsonData = customDataString.data(using: .utf8),
            let parsedData = try? JSONSerialization.jsonObject(with: jsonData)
                as? [String: Any],
            let action = parsedData["action"] as? String,
            let userId = parsedData["userId"] as? String
        {
            let matchupIds = parsedData["matchupIds"] as? [String]

            return NotificationData(
                action: action,
                userId: userId,
                matchupIds: matchupIds
            )
        }

        return nil
    }

    private func routeNotification(
        action: String,
        userId: String,
        matchupIds: [String]?,
        completion: ((UIBackgroundFetchResult) -> Void)?
    ) {
        switch action {
        case "sync_health_data":
            backgroundHealthSyncManager.performBackgroundHealthSync(for: userId)
            {
                success in
                DispatchQueue.main.async {
                    completion?(success ? .newData : .failed)
                }
            }
        case "refresh_matchup":
            if let matchupIds = matchupIds, !matchupIds.isEmpty {
                backgroundMatchupRefreshManager.performBackgroundMatchupRefresh(
                    for: matchupIds
                ) { result in
                    DispatchQueue.main.async {
                        completion?(result)
                    }
                }
            } else {
                // No specific matchup IDs, so we can't refresh by matchup ID
                AppLogger.warning("No matchup IDs provided for refresh_matchup action", category: .network)
                completion?(.noData)
            }
        default:
            AppLogger.warning(
                "Unknown notification action: \(action)",
                category: .network
            )
            completion?(.noData)
        }
    }
}

// MARK: - Supporting Types

private struct NotificationData {
    let action: String
    let userId: String
    let matchupIds: [String]?
}
