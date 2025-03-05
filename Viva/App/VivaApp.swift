import SwiftUI

@main
struct VivaApp: App {
    @StateObject var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        BackgroundTaskManager.shared.registerBackgroundTasks()
    }

    var body: some Scene {
        let vivaAppObjects = VivaAppObjects(userSession: appState.userSession)

        WindowGroup {
            SignInView(
                userSession: appState.userSession,
                authenticationManager: vivaAppObjects.authenticationManager,
                userProfileService: vivaAppObjects.userProfileService,
                friendService: vivaAppObjects.friendService,
                matchupService: vivaAppObjects.matchupService,
                userService: vivaAppObjects.userService,
                healthKitDataManager: vivaAppObjects.healthKitDataManager
            )
            .environmentObject(appState)
            .environmentObject(appState.userSession)
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
