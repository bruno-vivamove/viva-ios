import SwiftUI
import GoogleSignIn
import AuthenticationServices

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
                .environmentObject(vivaAppObjects.userProfileService)
                .environmentObject(vivaAppObjects.friendService)
                .environmentObject(vivaAppObjects.matchupService)
                .environmentObject(vivaAppObjects.userService)
                .environmentObject(vivaAppObjects.healthKitDataManager)
                .environmentObject(vivaAppObjects.userMeasurementService)
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
                
            case .background:
                // App is entering background, schedule background tasks
                AppLogger.info("App entered background - scheduling background refresh task", category: .general)
                if vivaAppObjects.userSession.isLoggedIn {
                    BackgroundTaskManager.shared.scheduleHealthUpdateTask()
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
    let memoryCapacity = 50 * 1024 * 1024 // 50 MB
    let diskCapacity = 100 * 1024 * 1024 // 100 MB
    let cache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: "vivaImages")
    URLCache.shared = cache
}
