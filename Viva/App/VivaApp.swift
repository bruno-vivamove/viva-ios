import SwiftUI
import GoogleSignIn
import AuthenticationServices
import Nuke
import BackgroundTasks
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var vivaAppObjects: VivaAppObjects?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Register for remote notifications
        registerForPushNotifications()
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        AppLogger.info("Device Token: \(token)", category: .general)
        
        // Store the device token for sending to server if needed
        UserDefaults.standard.set(token, forKey: "deviceToken")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        AppLogger.error("Failed to register for remote notifications: \(error)", category: .general)
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
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            AppLogger.info("Push notification permission granted: \(granted)", category: .general)
            if let error = error {
                AppLogger.error("Push notification permission error: \(error)", category: .general)
            }
            
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
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
