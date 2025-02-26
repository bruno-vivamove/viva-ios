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
        let authResponse = try await authService.signIn(email, password)
        let sessionResponse = try await sessionService.createSession(authResponse.idToken)
        userSession.setAccessToken(sessionResponse.accessToken)
        let userProfile = try await userProfileService.getCurrentUserProfile()

        await MainActor.run(){
            userSession.setLoggedIn(userProfile)
        }
    }
    
    func signUp(email: String, password: String) async throws {
        let authResponse = try await authService.signUp(email, password)
        let sessionResponse = try await sessionService.createSession(authResponse.idToken)
        userSession.setAccessToken(sessionResponse.accessToken)
        let userProfile = try await userProfileService.getCurrentUserProfile()
        
        await MainActor.run(){
            userSession.setLoggedIn(userProfile)
        }
    }

    func signOut() async {
        await MainActor.run(){
            userSession.setLoggedOut()
        }
    }
}
