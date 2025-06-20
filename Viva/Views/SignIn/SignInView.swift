import Foundation
import GoogleSignIn
import Lottie
import Security
import SwiftUI

struct SignInView: View {
    @EnvironmentObject var userSession: UserSession
    @EnvironmentObject var authenticationManager: AuthenticationManager

    private let logoWidth: CGFloat = 180

    var body: some View {
        VStack(spacing: VivaDesign.Spacing.large) {
            // Logo
            LogoHeader(width: logoWidth)

            Spacer()

            // Main Text
            MarketingText()

            Spacer()

            // Auth Buttons
            AuthButtonStack()
        }
        .padding(.vertical, VivaDesign.Spacing.large)
        .background(VivaDesign.Colors.background)
    }
}

struct LogoHeader: View {
    let width: CGFloat

    var body: some View {
        HStack {
            Spacer()
            Image("viva_logo")
                .resizable()
                .scaledToFit()
                .frame(width: width)
        }
        .padding(.trailing, VivaDesign.Spacing.introPadding)
    }
}

struct MarketingText: View {
    var body: some View {
        HStack {
            Spacer()
            VStack(alignment: .trailing, spacing: 0) {
                Text("LONG")
                    .font(VivaDesign.Typography.displayText())
                    .foregroundColor(VivaDesign.Colors.vivaGreen)

                Text("LIVE")
                    .font(VivaDesign.Typography.displayText())
                    .foregroundColor(VivaDesign.Colors.vivaGreen)

                Text("THE FIT")
                    .font(VivaDesign.Typography.displayText())
                    .foregroundColor(VivaDesign.Colors.primaryText)
            }
            .multilineTextAlignment(.trailing)
            .padding(.trailing, VivaDesign.Spacing.introPadding)
        }
    }
}

struct AuthButtonStack: View {
    @EnvironmentObject var userSession: UserSession
    @EnvironmentObject var authenticationManager: AuthenticationManager

    @State private var showSignInForm = false
    @State private var showSignUpForm = false
    @State private var loadingStates: [String: Bool] = [:]

    var body: some View {
        VStack(spacing: VivaDesign.Spacing.componentSmall) {
            // Sign Up Button
            VivaButton.primary(
                "Sign Up",
                size: .large,
                isLoading: loadingStates["Sign Up"] ?? false
            ) {
                showSignUpForm = true
            }

            // Basic Sign In Button
            VivaButton.outline(
                "Sign In",
                size: .large,
                isLoading: loadingStates["Sign In"] ?? false
            ) {
                showSignInForm = true
            }

            // Google Sign In Button
            VivaButton.outline(
                "Sign In with Google",
                size: .large,
                isLoading: loadingStates["Sign In with Google"] ?? false
            ) {
                executeGoogleSignIn()
            }
            .withIcon(Image("google_logo"))

            // Apple Sign In Button
            VivaButton.secondary(
                "Sign in with Apple",
                size: .large,
                isLoading: loadingStates["Sign in with Apple"] ?? false
            ) {
                executeAppleSignIn()
            }
            .withIcon(Image(systemName: "applelogo"))
        }
        .padding(.horizontal, VivaDesign.Spacing.introPadding)
        .sheet(isPresented: $showSignInForm) {
            SignInFormView(
                authManager: authenticationManager,
                userSession: userSession
            )
            .presentationBackground(.clear)
        }
        .sheet(isPresented: $showSignUpForm) {
            SignUpFormView(
                authManager: authenticationManager,
                userSession: userSession
            )
            .presentationBackground(.clear)
        }
    }

    private func executeGoogleSignIn() {
        let actionId = "Sign In with Google"
        loadingStates[actionId] = true

        authenticationManager.signInWithGoogle { result in
            DispatchQueue.main.async {
                loadingStates[actionId] = false

                switch result {
                case .success:
                    break  // Authentication successful, UI will update automatically
                case .cancelled:
                    break  // User cancelled, just clear loading state
                case .error(let error):
                    print(
                        "Google sign-in failed: \(error.localizedDescription)"
                    )
                // Could show error alert here if needed
                }
            }
        }
    }

    private func executeAppleSignIn() {
        let actionId = "Sign in with Apple"
        loadingStates[actionId] = true

        authenticationManager.signInWithApple { result in
            DispatchQueue.main.async {
                loadingStates[actionId] = false

                switch result {
                case .success:
                    break  // Authentication successful, UI will update automatically
                case .cancelled:
                    break  // User cancelled, just clear loading state
                case .error(let error):
                    print("Apple sign-in failed: \(error.localizedDescription)")
                // Could show error alert here if needed
                }
            }
        }
    }
}
