import SwiftUI

@main
struct VivaApp: App {
    @StateObject var vivaAppObjects = VivaAppObjects()
    @Environment(\.scenePhase) private var scenePhase

    init() {
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
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            print("App state changed: \(oldPhase) -> \(newPhase)")
            if newPhase == .background {
                print("App entered background - scheduling tasks")
                BackgroundTaskManager.shared.scheduleHealthUpdateTask()
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
