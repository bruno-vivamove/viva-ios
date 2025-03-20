import SwiftUI

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
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            print("App state changed: \(oldPhase) -> \(newPhase)")
            
            switch newPhase {
            case .active:
                // App became active, perform any necessary updates
                // This is a good place to refresh data
                print("App became active")
                
            case .background:
                // App is entering background, schedule background tasks
                print("App entered background - scheduling background refresh task")
                if vivaAppObjects.userSession.isLoggedIn {
                    BackgroundTaskManager.shared.scheduleHealthUpdateTask()
                }
                
            case .inactive:
                // App is inactive but visible
                print("App became inactive")
                
            @unknown default:
                print("Unknown scene phase: \(newPhase)")
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
