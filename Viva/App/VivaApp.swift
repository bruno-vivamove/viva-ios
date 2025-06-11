import SwiftUI
import GoogleSignIn
import AuthenticationServices
import Nuke
import BackgroundTasks
import UserNotifications
import FirebaseMessaging
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var vivaAppObjects: VivaAppObjects?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialize Firebase
        configureFirebase()
        
        // Set FCM messaging delegate after Firebase is configured
        Messaging.messaging().delegate = self
        
        // Register for remote notifications
        registerForPushNotifications()
        return true
    }
    
    private func configureFirebase() {
        // Read the file name from the Info.plist
        guard let plistFileName = Bundle.main.object(forInfoDictionaryKey: "FIREBASE_CONFIG_FILE") as? String else {
            // Fallback for safety, though this should not happen in a correctly configured project
            FirebaseApp.configure()
            AppLogger.error("FIREBASE_CONFIG_FILE not found in Info.plist. Falling back to default Firebase configuration.", category: .general)
            return
        }
        
        // Load the corresponding plist file
        if let filePath = Bundle.main.path(forResource: plistFileName, ofType: "plist"),
           let firebaseOptions = FirebaseOptions(contentsOfFile: filePath) {
            FirebaseApp.configure(options: firebaseOptions)
            AppLogger.info("Firebase configured using \(plistFileName).plist.", category: .general)
        } else {
            // Fallback to default configuration if specific file is not found
            FirebaseApp.configure()
            AppLogger.warning("Could not find \(plistFileName).plist. Falling back to default Firebase configuration.", category: .general)
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        AppLogger.info("APNS Device Token: \(token)", category: .general)
        
        // Store the device token for sending to server if needed
        UserDefaults.standard.set(token, forKey: "deviceToken")
        
        // Set APNS token for Firebase Messaging (improves FCM reliability)
        Messaging.messaging().apnsToken = deviceToken
        AppLogger.info("Set APNS token for Firebase Messaging", category: .network)
        
        // Note: FCM token registration is handled by MessagingDelegate
        // No need to manually call registerFCMTokenIfNeeded here
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        AppLogger.error("Failed to register for remote notifications: \(error)", category: .general)
                
        // Check if running in simulator
        #if targetEnvironment(simulator)
        AppLogger.info("Running in iOS Simulator - APNS not available, but FCM can still work", category: .network)
        #endif
    }
    

    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        AppLogger.info("Received remote notification: \(userInfo)", category: .general)
        
        // Check if this is a silent notification with custom data
        guard let customData = userInfo["custom_data"] as? [String: Any],
              let action = customData["action"] as? String,
              let userId = customData["user_id"] as? String else {
            completionHandler(.noData)
            return
        }
        
        // Route to appropriate handler based on action type
        switch action {
        case "sync_health_data":
            AppLogger.info("Processing health data sync for user: \(userId)", category: .data)
            performBackgroundHealthSync(for: userId) { success in
                DispatchQueue.main.async {
                    completionHandler(success ? .newData : .failed)
                }
            }
            
        case "refresh_matchups":
            AppLogger.info("Processing matchup refresh for user: \(userId)", category: .data)
            performBackgroundMatchupRefresh(for: userId) { success in
                DispatchQueue.main.async {
                    completionHandler(success ? .newData : .failed)
                }
            }
            
        default:
            AppLogger.warning("Unknown notification action: \(action)", category: .general)
            completionHandler(.noData)
        }
    }
    
    private func registerForPushNotifications() {
        AppLogger.info("Starting push notification registration process", category: .general)
        
        UNUserNotificationCenter.current().delegate = self
        
        // First check current authorization status
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            AppLogger.info("Current notification authorization status: \(settings.authorizationStatus.rawValue)", category: .general)
            
            switch settings.authorizationStatus {
            case .notDetermined:
                AppLogger.info("Notification permission not determined, requesting authorization", category: .general)
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    AppLogger.info("Push notification permission granted: \(granted)", category: .general)
                    if let error = error {
                        AppLogger.error("Push notification permission error: \(error)", category: .general)
                        return
                    }
                    
                    if granted {
                        AppLogger.info("Push notification permission granted, registering for remote notifications", category: .general)
                        DispatchQueue.main.async {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    } else {
                        AppLogger.warning("Push notification permission denied, cannot register for remote notifications", category: .general)
                    }
                }
            case .denied:
                AppLogger.warning("Push notification permission denied by user", category: .general)
            case .authorized, .provisional:
                AppLogger.info("Push notification already authorized, registering for remote notifications", category: .general)
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            case .ephemeral:
                AppLogger.info("Push notification ephemeral authorization, registering for remote notifications", category: .general)
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            @unknown default:
                AppLogger.warning("Unknown authorization status: \(settings.authorizationStatus.rawValue)", category: .general)
            }
        }
    }
    
    private func performBackgroundHealthSync(for userId: String, completion: @escaping (Bool) -> Void) {
        guard let vivaAppObjects = vivaAppObjects else {
            AppLogger.error("VivaAppObjects not available for background health sync", category: .data)
            completion(false)
            return
        }
        
        vivaAppObjects.backgroundHealthSyncManager.performBackgroundHealthSync(for: userId, completion: completion)
    }
    
    private func performBackgroundMatchupRefresh(for userId: String, completion: @escaping (Bool) -> Void) {
        guard let vivaAppObjects = vivaAppObjects else {
            AppLogger.error("VivaAppObjects not available for background matchup refresh", category: .data)
            completion(false)
            return
        }
        
        vivaAppObjects.backgroundMatchupRefreshManager.performBackgroundMatchupRefresh(for: userId, completion: completion)
    }
    
    // MARK: - FCM Token Management
    
    /// Manually registers FCM token with backend when called explicitly
    /// This is now only used for manual refresh scenarios
    func registerFCMTokenIfNeeded() {
        guard let vivaAppObjects = vivaAppObjects,
              vivaAppObjects.userSession.isLoggedIn else {
            AppLogger.info("User not logged in, skipping FCM token registration", category: .network)
            return
        }
        
        // Remove the APNS token check - FCM can work without it
        Messaging.messaging().token { [weak self] token, error in
            if let error = error {
                AppLogger.error("Error fetching FCM token: \(error)", category: .network)
                return
            }
            
            guard let token = token else {
                AppLogger.warning("FCM token is nil", category: .network)
                return
            }
            
            AppLogger.info("Retrieved FCM token (manual): \(token.prefix(8))...", category: .network)
            self?.registerDeviceToken(token)
        }
    }
    
    /// Registers device token with backend
    private func registerDeviceToken(_ fcmToken: String) {
        guard let vivaAppObjects = vivaAppObjects else {
            AppLogger.error("VivaAppObjects not available for device token registration", category: .network)
            return
        }
        
        // Only register if user is logged in
        guard vivaAppObjects.userSession.isLoggedIn else {
            AppLogger.info("User not logged in, skipping FCM token registration with backend", category: .network)
            return
        }
        
        Task {
            do {
                try await vivaAppObjects.deviceTokenService.manageDeviceToken(fcmToken: fcmToken)
                AppLogger.info("Successfully registered FCM token with backend", category: .network)
            } catch {
                AppLogger.error("Failed to register FCM token: \(error)", category: .network)
            }
        }
    }
}

// MARK: - MessagingDelegate

extension AppDelegate: MessagingDelegate {
    /// Called when FCM token is refreshed or initially generated
    /// This is the primary way FCM tokens are obtained - it works with or without APNS
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        AppLogger.info("FCM registration token received/refreshed", category: .network)
        
        guard let fcmToken = fcmToken else {
            AppLogger.warning("Received nil FCM token", category: .network)
            return
        }
        
        let hasAPNSToken = messaging.apnsToken != nil
        AppLogger.info("FCM token received: \(fcmToken.prefix(8))..., APNS token available: \(hasAPNSToken)", category: .network)
        
        // Register the token with the backend
        registerDeviceToken(fcmToken)
    }
}

@main
struct VivaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var vivaAppObjects = VivaAppObjects()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        configureVivaImageCache()
    }

    var body: some Scene {
        WindowGroup {
            AppContainerView()
                .environmentObject(vivaAppObjects.userSession)
                .environmentObject(vivaAppObjects.authManager)
                .environmentObject(vivaAppObjects.friendService)
                .environmentObject(vivaAppObjects.statsService)
                .environmentObject(vivaAppObjects.matchupService)
                .environmentObject(vivaAppObjects.userService)
                .environmentObject(vivaAppObjects.healthKitDataManager)
                .environmentObject(vivaAppObjects.userMeasurementService)
                .environmentObject(vivaAppObjects.errorManager)
                .onOpenURL { url in
                    if url.absoluteString.contains("google") {
                        GIDSignIn.sharedInstance.handle(url)
                    }
                }
                .onAppear {
                    // Connect appDelegate to vivaAppObjects
                    appDelegate.vivaAppObjects = vivaAppObjects
                    
                    // Register background tasks at app startup
                    vivaAppObjects.backgroundTaskManager.registerBackgroundTasks()
                    
                    // Check for existing Apple sign-in session on app launch
                    checkAppleSignInState()
                }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            AppLogger.info("App state changed: \(oldPhase) -> \(newPhase)", category: .general)
            
            switch newPhase {
            case .active:
                // App became active, perform any necessary updates
                // This is a good place to refresh data
                AppLogger.info("App became active", category: .general)
                
                // Setup HealthKit background observers when app becomes active
                if vivaAppObjects.healthKitDataManager.isAuthorized {
                    vivaAppObjects.healthKitDataManager.setupBackgroundObservers()
                    AppLogger.info("Set up HealthKit background observers", category: .health)
                } else {
                    // Request HealthKit authorization if not already authorized
                    vivaAppObjects.healthKitDataManager.requestAuthorization()
                    AppLogger.info("Requested HealthKit authorization", category: .health)
                }
                
                // FCM token registration is primarily handled by MessagingDelegate
                // Only manually refresh if there are specific reasons to do so
                
            case .background:
                // App is entering background
                AppLogger.info("App entered background", category: .general)
                
                // Schedule background health update task if user is logged in
                if vivaAppObjects.userSession.isLoggedIn {
                    let request = BGProcessingTaskRequest(identifier: BackgroundTaskManager.backgroundHealthUpdateTaskIdentifier)
                    request.requiresNetworkConnectivity = true
                    request.requiresExternalPower = false
                    
                    do {
                        try BGTaskScheduler.shared.submit(request)
                        AppLogger.info("✅ Successfully scheduled background health update task", category: .general)
                    } catch let error as NSError {
                        let errorDescription = switch error.code {
                        case 1: "BGTaskSchedulerErrorCodeUnavailable - Background tasks not available (requires physical device, background app refresh enabled)"
                        case 2: "BGTaskSchedulerErrorCodeTooManyPendingTaskRequests - Too many pending requests"
                        case 3: "BGTaskSchedulerErrorCodeNotPermitted - App not permitted to use background tasks"
                        default: "Unknown BGTaskScheduler error code \(error.code)"
                        }
                        AppLogger.error("❌ Failed to schedule background task: \(errorDescription)", category: .general)
                    }
                }
                
            case .inactive:
                // App is inactive but visible
                AppLogger.info("App became inactive", category: .general)
                
            @unknown default:
                AppLogger.warning("Unknown scene phase: \(newPhase)", category: .general)
            }
        }
    }
    
    // Check for existing Apple sign-in state
    private func checkAppleSignInState() {
        // This checks if the user has previously signed in with Apple
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let appleUserId = vivaAppObjects.userSession.getAppleUserId()
        
        if let userId = appleUserId {
            appleIDProvider.getCredentialState(forUserID: userId) { (credentialState, error) in
                switch credentialState {
                case .authorized:
                    // The Apple ID credential is valid
                    AppLogger.info("Apple ID credential is still valid", category: .auth)
                    
                case .revoked:
                    // The Apple ID credential was revoked, sign out
                    AppLogger.warning("Apple ID credential was revoked", category: .auth)
                    self.vivaAppObjects.userSession.deleteAppleUserId()
                    
                case .notFound:
                    // No Apple ID credential was found, sign out if needed
                    AppLogger.warning("No Apple ID credential was found", category: .auth)
                    self.vivaAppObjects.userSession.deleteAppleUserId()
                    
                default:
                    break
                }
            }
        }
    }
}

struct AppContainerView: View {
    @EnvironmentObject var userSession: UserSession
    
    var body: some View {
        ZStack {
            VivaDesign.Colors.background
                .ignoresSafeArea()
            
            if userSession.isLoggedIn {
                MainView()
                    .transition(.move(edge: .trailing))
            } else {
                SignInView()
                    .transition(.opacity)
            }
        }
    }
}

// Configure the shared URLCache for image caching
func configureVivaImageCache() {
    // Configure memory cache
    ImageCache.shared.costLimit = 50 * 1024 * 1024 // 50 MB
    ImageCache.shared.countLimit = 500 // Limit number of items in memory cache
    ImageCache.shared.ttl = 120 // Invalidate images after 120 seconds
    
    // Configure disk cache
    let dataCache = try? DataCache(name: "vivaImages")
    dataCache?.sizeLimit = 100 * 1024 * 1024 // 100 MB
    
    // Create custom pipeline with data cache
    let pipeline = ImagePipeline {
        $0.dataCache = dataCache
        $0.imageCache = ImageCache.shared
        
        // Use custom data loader to disable default URLCache
        let config = URLSessionConfiguration.default
        config.urlCache = nil // Disable URLCache since we're using DataCache
        $0.dataLoader = DataLoader(configuration: config)
        
        // Additional performance configurations
        $0.isProgressiveDecodingEnabled = true
        $0.isRateLimiterEnabled = true
        
        // Configure caching behavior
        $0.dataCachePolicy = .storeOriginalData // Store only original image data
    }
    
    // Set as the shared pipeline
    ImagePipeline.shared = pipeline
}
