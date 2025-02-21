//
//  VivaApp.swift
//  Viva
//
//  Created by Bruno Souto on 1/8/25.
//

import SwiftUI

@main
struct VivaApp: App {
    @StateObject var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        let vivaAppObjects = VivaAppObjects(userSession: appState.userSession)

        WindowGroup {
            SignInView(
                userSession: appState.userSession,
                authenticationManager: vivaAppObjects.authenticationManager,
                userProfileService: vivaAppObjects.userProfileService,
                friendService: vivaAppObjects.friendService,
                matchupService: vivaAppObjects.matchupService,
                userService: vivaAppObjects.userService
            )
            .environmentObject(appState)
            .environmentObject(appState.userSession)
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                Task {
                    do {
                        let healthService = HealthService(
                            networkClient: vivaAppObjects.appNetworkClient)
                        _ = try await healthService.ping()
                    } catch {
                        print("Health ping failed: \(error)")
                    }
                }
            }
        }
    }
}
