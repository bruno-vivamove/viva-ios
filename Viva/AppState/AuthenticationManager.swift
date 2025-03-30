import Foundation
import Security
import SwiftUI

final class AuthenticationManager: ObservableObject {
    let userSession: UserSession
    let authService: AuthService
    let sessionService: SessionService
    let userProfileService: UserProfileService

    init(
        userSession: UserSession, authService: AuthService,
        sessionService: SessionService, userProfileService: UserProfileService
    ) {
        self.userSession = userSession
        self.authService = authService
        self.sessionService = sessionService
        self.userProfileService = userProfileService
    }

    func signIn(email: String, password: String) async throws {
        AppLogger.info("Attempting to sign in user with email: \(email.logPrivate())", category: .auth)
        
        do {
            let authResponse = try await authService.signIn(email, password)
            AppLogger.debug("Authentication successful, obtaining session", category: .auth)
            
            try await createSession(idToken: authResponse.idToken)
            
            AppLogger.info("User signed in successfully", category: .auth)
        } catch {
            AppLogger.error("Sign in failed: \(error.localizedDescription)", category: .auth)
            throw error
        }
    }

    func createSession(idToken: String) async throws {
        AppLogger.debug("Creating session with idToken", category: .auth)
        let sessionResponse = try await sessionService.createSession(idToken)
        
        await MainActor.run {
            userSession.setLoggedIn(
                userProfile: sessionResponse.userProfile,
                accessToken: sessionResponse.accessToken,
                refreshToken: sessionResponse.refreshToken
            )
        }
    }

    func signUp(email: String, password: String) async throws {
        AppLogger.info("Attempting to register new user with email: \(email.logPrivate())", category: .auth)
        
        do {
            let authResponse = try await authService.signUp(email, password)
            AppLogger.debug("Registration successful, obtaining session", category: .auth)
            
            try await createSession(idToken: authResponse.idToken)
            
            AppLogger.info("User registered and signed in successfully", category: .auth)
        } catch {
            AppLogger.error("Registration failed: \(error.localizedDescription)", category: .auth)
            throw error
        }
    }

    func signOut() async {
        AppLogger.info("User signing out", category: .auth)
        await userSession.setLoggedOut()
        AppLogger.debug("User signed out successfully", category: .auth)
    }
}
