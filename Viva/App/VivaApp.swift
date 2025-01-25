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
        let authenticationManager =  AuthenticationManager(
            userSession: appState.userSession,
            authService: AuthService(
                networkClient: NetworkClient(
                    settings: AuthNetworkClientSettings())),
            sessionService: SessionService(
                networkClient: NetworkClient(
                    settings: AppWithNoSessionNetworkClientSettings())),
            userProfileService: UserProfileService(
                networkClient: NetworkClient(
                    settings: AppNetworkClientSettings(userSession: appState.userSession)
                ),
                userSession: appState.userSession)
        )

        WindowGroup {
            SignInView(
                userSession: appState.userSession,
                authenticationManager: authenticationManager
            )
            .environmentObject(appState)
            .environmentObject(appState.userSession)
        }
    }
}
