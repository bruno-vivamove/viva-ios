import SwiftUI
import GoogleSignIn
import AuthenticationServices
import Nuke
import UserNotifications
import FirebaseMessaging
import FirebaseCore

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
                    
                    // Setup notifications
                    appDelegate.setupNotifications()
                    
                    // Check for existing Apple sign-in session
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

class AppDelegate: NSObject, UIApplicationDelegate {
    var vivaAppObjects: VivaAppObjects?
    private var notificationService: NotificationService?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialize Firebase
        FirebaseUtil.configureFirebase()
        
        // Set FCM messaging delegate
        Messaging.messaging().delegate = self
        
        // Set UNUserNotificationCenter delegate
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        notificationService?.handleAPNSTokenRegistration(deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        notificationService?.handleAPNSTokenRegistrationFailure(error)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        notificationService?.processNotification(userInfo, completion: completionHandler)
    }
    
    // MARK: - Setup
    
    func setupNotifications() {
        notificationService = vivaAppObjects?.notificationService
        notificationService?.registerForPushNotifications()
    }
}

// MARK: - MessagingDelegate

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else {
            AppLogger.warning("Received nil FCM token", category: .network)
            return
        }
        
        notificationService?.handleFCMTokenRefresh(fcmToken)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        AppLogger.info("Notification received in foreground", category: .network)
        
        notificationService?.processNotification(userInfo)
        
        // Don't show notification in foreground for silent notifications
        completionHandler([])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        AppLogger.info("Notification tapped", category: .network)
        
        notificationService?.processNotification(userInfo)
        
        completionHandler()
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
