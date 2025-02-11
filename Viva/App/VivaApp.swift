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

    var body: some Scene {
        let vivaAppObjects = VivaAppObjects(userSession: appState.userSession)

        WindowGroup {
            SignInView(
                userSession: appState.userSession,
                authenticationManager: vivaAppObjects.authenticationManager,
                userProfileService: vivaAppObjects.userProfileService,
                friendService: vivaAppObjects.friendService,
                matchupService: vivaAppObjects.matchupService
            )
            .environmentObject(appState)
            .environmentObject(appState.userSession)
        }
    }
}
