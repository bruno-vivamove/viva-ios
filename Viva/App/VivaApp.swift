import SwiftUI

@main
struct VivaApp: App {
    @StateObject var vivaAppObjects = VivaAppObjects()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        BackgroundTaskManager.shared.registerBackgroundTasks()
    }

    var body: some Scene {

        WindowGroup {
            SignInView()
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
