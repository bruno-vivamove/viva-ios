import Foundation
import Security
import SwiftUI
import GoogleSignIn
import AuthenticationServices

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
        
        // Clear Apple Sign In state if it exists
        UserDefaults.standard.removeObject(forKey: "appleAuthorizedUserIdKey")
        
        await userSession.setLoggedOut()
        AppLogger.debug("User signed out successfully", category: .auth)
    }
    
    func signInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            AppLogger.error("Unable to find root view controller", category: .auth)
            return
        }
        
        // Start the sign-in flow.
        GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController
        ) { [weak self] signInResult, error in
            guard let self = self else { return }
            
            if let error = error {
                AppLogger.error("Error signing in with Google: \(error.localizedDescription)", category: .auth)
                return
            }

            guard let signInResult = signInResult else {
                AppLogger.error("Missing authentication object", category: .auth)
                return
            }

            signInResult.user.refreshTokensIfNeeded { user, error in
                if let error = error {
                    AppLogger.error("Error refreshing tokens: \(error.localizedDescription)", category: .auth)
                    return
                }

                guard let user = user, let idToken = user.idToken else {
                    AppLogger.error("Missing user or ID token after refreshing tokens", category: .auth)
                    return
                }

                // Use createSession method to handle session creation
                Task {
                    do {
                        try await self.createSession(idToken: idToken.tokenString)
                        AppLogger.info("User signed in with Google successfully", category: .auth)
                    } catch {
                        AppLogger.error("Failed to create session: \(error.localizedDescription)", category: .auth)
                    }
                }
            }
        }
    }
    

    func signInWithApple() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = AppleSignInDelegate.shared
        authorizationController.presentationContextProvider = AppleSignInDelegate.shared
        
        // Keep a reference to the auth manager
        AppleSignInDelegate.shared.authManager = self
        
        authorizationController.performRequests()
    }
    
    func handleAppleSignInCompletion(with idToken: String, userId: String, fullName: PersonNameComponents?, email: String?) {
        AppLogger.info("User signed in with Apple successfully, creating session", category: .auth)
        
        // Store the Apple user ID in UserDefaults for credential state checking
        UserDefaults.standard.set(userId, forKey: "appleAuthorizedUserIdKey")
        
        Task {
            do {
                try await createSession(idToken: idToken)
                
                // Store user details if this is a new account (email and name are only provided on first sign-in)
                if let email = email, let fullName = fullName {
                    AppLogger.info("Received user details from Apple: \(fullName.givenName ?? "") \(fullName.familyName ?? "")", category: .auth)
                    // TODO: Update user profile with name if needed
                }
                
                AppLogger.info("User signed in with Apple successfully", category: .auth)
            } catch {
                AppLogger.error("Failed to create session with Apple ID token: \(error.localizedDescription)", category: .auth)
            }
        }
    }
    
    func resetPassword(email: String) async throws -> AuthService.ResetPasswordResponse {
        AppLogger.info("Requesting password reset for email: \(email.logPrivate())", category: .auth)
        
        do {
            let resetResponse = try await authService.resetPassword(email: email)
            AppLogger.info("Password reset email sent successfully to: \(resetResponse.email)", category: .auth)
            return resetResponse
        } catch {
            AppLogger.error("Password reset failed: \(error.localizedDescription)", category: .auth)
            throw error
        }
    }
}

// Delegate to handle Apple Sign In responses
class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    static let shared = AppleSignInDelegate()
    
    // Weak reference to avoid retain cycles
    weak var authManager: AuthenticationManager?
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window available")
        }
        return window
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let idTokenData = appleIDCredential.identityToken,
              let idToken = String(data: idTokenData, encoding: .utf8),
              let authManager = authManager else {
            AppLogger.error("Failed to get Apple ID token", category: .auth)
            return
        }
        
        let userId = appleIDCredential.user
        let fullName = appleIDCredential.fullName
        let email = appleIDCredential.email
        
        authManager.handleAppleSignInCompletion(with: idToken, userId: userId, fullName: fullName, email: email)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        AppLogger.error("Apple sign in failed: \(error.localizedDescription)", category: .auth)
    }
}
