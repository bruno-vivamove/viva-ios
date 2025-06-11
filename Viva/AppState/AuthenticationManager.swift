import AuthenticationServices
import Foundation
import GoogleSignIn
import Security
import SwiftUI
import UserNotifications
import FirebaseMessaging

enum AuthResult {
    case success
    case cancelled
    case error(Error)
}

final class AuthenticationManager: ObservableObject {
    let userSession: UserSession
    let authService: AuthService
    let sessionService: SessionService
    let deviceTokenService: DeviceTokenService

    init(
        userSession: UserSession,
        authService: AuthService,
        sessionService: SessionService,
        deviceTokenService: DeviceTokenService
    ) {
        self.userSession = userSession
        self.authService = authService
        self.sessionService = sessionService
        self.deviceTokenService = deviceTokenService
    }

    func signIn(email: String, password: String) async throws {
        AppLogger.info(
            "Attempting to sign in user with email: \(email.logPrivate())",
            category: .auth
        )

        do {
            let authResponse = try await authService.signIn(email, password)
            AppLogger.debug(
                "Authentication successful, obtaining session",
                category: .auth
            )

            try await createSession(idToken: authResponse.idToken)

            AppLogger.info("User signed in successfully", category: .auth)
        } catch {
            AppLogger.error(
                "Sign in failed: \(error.localizedDescription)",
                category: .auth
            )
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
        
        // Register device token after successful session creation
        await registerDeviceTokenIfNeeded()
    }

    func signUp(email: String, password: String) async throws {
        AppLogger.info(
            "Attempting to register new user with email: \(email.logPrivate())",
            category: .auth
        )

        do {
            let authResponse = try await authService.signUp(email, password)
            AppLogger.debug(
                "Registration successful, obtaining session",
                category: .auth
            )

            try await createSession(idToken: authResponse.idToken)

            AppLogger.info(
                "User registered and signed in successfully",
                category: .auth
            )
        } catch {
            AppLogger.error(
                "Registration failed: \(error.localizedDescription)",
                category: .auth
            )
            throw error
        }
    }

    func signOut() async {
        AppLogger.info("User signing out", category: .auth)

        // Clean up device token before clearing session
        await deviceTokenService.cleanupDeviceToken()

        // Clear Apple Sign In state if it exists
        userSession.deleteAppleUserId()

        await userSession.setLoggedOut()
        AppLogger.debug("User signed out successfully", category: .auth)
    }

    func signInWithGoogle(completion: @escaping (AuthResult) -> Void = { _ in })
    {
        guard
            let windowScene = UIApplication.shared.connectedScenes.first
                as? UIWindowScene,
            let rootViewController = windowScene.windows.first?
                .rootViewController
        else {
            AppLogger.error(
                "Unable to find root view controller",
                category: .auth
            )
            completion(
                .error(
                    NSError(
                        domain: "AuthError",
                        code: -1,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "Unable to find root view controller"
                        ]
                    )
                )
            )
            return
        }

        // Start the sign-in flow.
        GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController
        ) { [weak self] signInResult, error in
            guard let self = self else {
                completion(
                    .error(
                        NSError(
                            domain: "AuthError",
                            code: -1,
                            userInfo: [
                                NSLocalizedDescriptionKey:
                                    "Authentication manager deallocated"
                            ]
                        )
                    )
                )
                return
            }

            if let error = error {
                AppLogger.error(
                    "Error signing in with Google: \(error.localizedDescription)",
                    category: .auth
                )
                // Check if error is user cancellation
                if error.localizedDescription.contains("cancel")
                    || (error as NSError).code == -5
                {
                    completion(.cancelled)
                } else {
                    completion(.error(error))
                }
                return
            }

            guard let signInResult = signInResult else {
                AppLogger.error(
                    "Missing authentication object",
                    category: .auth
                )
                completion(
                    .error(
                        NSError(
                            domain: "AuthError",
                            code: -1,
                            userInfo: [
                                NSLocalizedDescriptionKey:
                                    "Missing authentication object"
                            ]
                        )
                    )
                )
                return
            }

            signInResult.user.refreshTokensIfNeeded { user, error in
                if let error = error {
                    AppLogger.error(
                        "Error refreshing tokens: \(error.localizedDescription)",
                        category: .auth
                    )
                    completion(.error(error))
                    return
                }

                guard let user = user, let idToken = user.idToken else {
                    AppLogger.error(
                        "Missing user or ID token after refreshing tokens",
                        category: .auth
                    )
                    completion(
                        .error(
                            NSError(
                                domain: "AuthError",
                                code: -1,
                                userInfo: [
                                    NSLocalizedDescriptionKey:
                                        "Missing user or ID token"
                                ]
                            )
                        )
                    )
                    return
                }

                // Use createSession method to handle session creation
                Task {
                    do {
                        try await self.createSession(
                            idToken: idToken.tokenString
                        )
                        AppLogger.info(
                            "User signed in with Google successfully",
                            category: .auth
                        )
                        await MainActor.run {
                            completion(.success)
                        }
                    } catch {
                        AppLogger.error(
                            "Failed to create session: \(error.localizedDescription)",
                            category: .auth
                        )
                        await MainActor.run {
                            completion(.error(error))
                        }
                    }
                }
            }
        }
    }

    func signInWithApple(completion: @escaping (AuthResult) -> Void = { _ in })
    {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let authorizationController = ASAuthorizationController(
            authorizationRequests: [request])
        authorizationController.delegate = AppleSignInDelegate.shared
        authorizationController.presentationContextProvider =
            AppleSignInDelegate.shared

        // Keep a reference to the auth manager and completion
        AppleSignInDelegate.shared.authManager = self
        AppleSignInDelegate.shared.completion = completion

        authorizationController.performRequests()
    }

    func handleAppleSignInCompletion(
        with idToken: String,
        userId: String,
        fullName: PersonNameComponents?,
        email: String?,
        completion: @escaping (AuthResult) -> Void
    ) {
        AppLogger.info(
            "User signed in with Apple successfully, creating session",
            category: .auth
        )

        // Store the Apple user ID in secure Keychain for credential state checking
        userSession.storeAppleUserId(userId)

        Task {
            do {
                try await createSession(idToken: idToken)

                // Store user details if this is a new account (email and name are only provided on first sign-in)
                if email != nil, let fullName = fullName {
                    AppLogger.info(
                        "Received user details from Apple: \(fullName.givenName ?? "") \(fullName.familyName ?? "")",
                        category: .auth
                    )
                    // TODO: Update user profile with name if needed
                }

                AppLogger.info(
                    "User signed in with Apple successfully",
                    category: .auth
                )
                await MainActor.run {
                    completion(.success)
                }
            } catch {
                AppLogger.error(
                    "Failed to create session with Apple ID token: \(error.localizedDescription)",
                    category: .auth
                )
                await MainActor.run {
                    completion(.error(error))
                }
            }
        }
    }

    func resetPassword(email: String) async throws
        -> AuthService.ResetPasswordResponse
    {
        AppLogger.info(
            "Requesting password reset for email: \(email.logPrivate())",
            category: .auth
        )

        do {
            let resetResponse = try await authService.resetPassword(
                email: email
            )
            AppLogger.info(
                "Password reset email sent successfully to: \(resetResponse.email)",
                category: .auth
            )
            return resetResponse
        } catch {
            AppLogger.error(
                "Password reset failed: \(error.localizedDescription)",
                category: .auth
            )
            throw error
        }
    }
    
    // MARK: - Device Token Management
    
    /// Registers device token with backend if user is authenticated and push notifications are enabled
    private func registerDeviceTokenIfNeeded() async {
        guard userSession.isLoggedIn else {
            AppLogger.info("User not logged in, skipping device token registration", category: .auth)
            return
        }
        
        // Check if push notifications are authorized
        let notificationSettings = await UNUserNotificationCenter.current().notificationSettings()
        guard notificationSettings.authorizationStatus == .authorized else {
            AppLogger.info("Push notifications not authorized, skipping device token registration", category: .auth)
            return
        }
        
        // Get FCM token and register
        guard let fcmToken = await getFCMToken() else {
            AppLogger.warning("Failed to get FCM token for registration", category: .auth)
            return
        }
        
        do {
            try await deviceTokenService.manageDeviceToken(fcmToken: fcmToken)
            AppLogger.info("Successfully registered device token after authentication", category: .auth)
        } catch {
            AppLogger.error("Failed to register device token after authentication: \(error)", category: .auth)
        }
    }
    
    /// Gets FCM token from Firebase Messaging
    private func getFCMToken() async -> String? {
        do {
            let token = try await Messaging.messaging().token()
            AppLogger.info("Retrieved FCM token: \(token.prefix(8))...", category: .auth)
            return token
        } catch {
            AppLogger.error("Failed to get FCM token: \(error)", category: .auth)
            return nil
        }
    }
}

// Delegate to handle Apple Sign In responses
class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding
{
    static let shared = AppleSignInDelegate()

    // Weak reference to avoid retain cycles
    weak var authManager: AuthenticationManager?
    var completion: ((AuthResult) -> Void)?

    func presentationAnchor(for controller: ASAuthorizationController)
        -> ASPresentationAnchor
    {
        guard
            let windowScene = UIApplication.shared.connectedScenes.first
                as? UIWindowScene,
            let window = windowScene.windows.first
        else {
            AppLogger.error(
                "No window available for Apple Sign In presentation",
                category: .auth
            )
            // Return a new window as fallback to prevent crash
            let fallbackWindow = UIWindow()
            fallbackWindow.makeKeyAndVisible()
            return fallbackWindow
        }
        return window
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard
            let appleIDCredential = authorization.credential
                as? ASAuthorizationAppleIDCredential,
            let idTokenData = appleIDCredential.identityToken,
            let idToken = String(data: idTokenData, encoding: .utf8),
            let authManager = authManager,
            let completion = completion
        else {
            AppLogger.error("Failed to get Apple ID token", category: .auth)
            completion?(
                .error(
                    NSError(
                        domain: "AuthError",
                        code: -1,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "Failed to get Apple ID token"
                        ]
                    )
                )
            )
            return
        }

        let userId = appleIDCredential.user
        let fullName = appleIDCredential.fullName
        let email = appleIDCredential.email

        authManager.handleAppleSignInCompletion(
            with: idToken,
            userId: userId,
            fullName: fullName,
            email: email,
            completion: completion
        )

        // Clear references to prevent retain cycles
        self.authManager = nil
        self.completion = nil
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        AppLogger.error(
            "Apple sign in failed: \(error.localizedDescription)",
            category: .auth
        )

        // Store completion handler before clearing
        let completionHandler = completion

        // Clear references to prevent retain cycles
        self.authManager = nil
        self.completion = nil

        // Check if error is user cancellation
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                completionHandler?(.cancelled)
            case .failed, .invalidResponse, .notHandled, .notInteractive,
                    .matchedExcludedCredential, .credentialImport, .credentialExport,
                .unknown:
                completionHandler?(.error(error))
            @unknown default:
                completionHandler?(.error(error))
            }
        } else {
            completionHandler?(.error(error))
        }
    }
}
