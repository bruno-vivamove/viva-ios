import SwiftUI
import GoogleSignIn
import AuthenticationServices
import Nuke

@main
struct VivaApp: App {
    @StateObject var vivaAppObjects = VivaAppObjects()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Register background tasks at app startup
        BackgroundTaskManager.shared.registerBackgroundTasks()
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
        let appleIdKeychain = UserDefaults.standard.string(forKey: "appleAuthorizedUserIdKey")
        
        if let userId = appleIdKeychain {
            appleIDProvider.getCredentialState(forUserID: userId) { (credentialState, error) in
                switch credentialState {
                case .authorized:
                    // The Apple ID credential is valid
                    AppLogger.info("Apple ID credential is still valid", category: .auth)
                    
                case .revoked:
                    // The Apple ID credential was revoked, sign out
                    AppLogger.warning("Apple ID credential was revoked", category: .auth)
                    UserDefaults.standard.removeObject(forKey: "appleAuthorizedUserIdKey")
                    
                case .notFound:
                    // No Apple ID credential was found, sign out if needed
                    AppLogger.warning("No Apple ID credential was found", category: .auth)
                    UserDefaults.standard.removeObject(forKey: "appleAuthorizedUserIdKey")
                    
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
