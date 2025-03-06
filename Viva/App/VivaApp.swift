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
            SignInView(
                userSession: vivaAppObjects.userSession,
                authenticationManager: vivaAppObjects.authenticationManager,
                userProfileService: vivaAppObjects.userProfileService,
                friendService: vivaAppObjects.friendService,
                matchupService: vivaAppObjects.matchupService,
                userService: vivaAppObjects.userService,
                healthKitDataManager: vivaAppObjects.healthKitDataManager
            )
            .environmentObject(vivaAppObjects.userSession)
            .environmentObject(vivaAppObjects.authenticationManager)
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
