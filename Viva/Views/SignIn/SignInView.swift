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
        VStack(spacing: VivaDesign.Spacing.medium) {
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
                .padding(.trailing, VivaDesign.Spacing.medium)
        }
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
            .padding(.trailing, VivaDesign.Spacing.medium)
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
        VStack(spacing: VivaDesign.Spacing.small) {
            // Sign Up Button
            AuthButtonView(
                title: "Sign Up",
                style: .primary,
                isLoading: loadingStates["Sign Up"] ?? false
            ) {
                showSignUpForm = true
            }

            // Basic Sign In Button
            AuthButtonView(
                title: "Sign In",
                style: .secondary,
                isLoading: loadingStates["Sign In"] ?? false
            ) {
                showSignInForm = true
            }

            // Google Sign In Button
            AuthButtonView(
                title: "Sign In with Google",
                style: .secondary,
                image: Image("google_logo"),
                isLoading: loadingStates["Sign In with Google"] ?? false
            ) {
                executeGoogleSignIn()
            }

            // Apple Sign In Button
            AuthButtonView(
                title: "Sign in with Apple",
                style: .white,
                image: Image(systemName: "applelogo"),
                isLoading: loadingStates["Sign in with Apple"] ?? false
            ) {
                executeAppleSignIn()
            }
        }
        .padding(.horizontal, VivaDesign.Spacing.large)
        .sheet(isPresented: $showSignInForm) {
            SignInFormView(
                authManager: authenticationManager, userSession: userSession
            )
            .presentationBackground(.clear)
        }
        .sheet(isPresented: $showSignUpForm) {
            SignUpFormView(
                authManager: authenticationManager, userSession: userSession
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
                    break // Authentication successful, UI will update automatically
                case .cancelled:
                    break // User cancelled, just clear loading state
                case .error(let error):
                    print("Google sign-in failed: \(error.localizedDescription)")
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
                    break // Authentication successful, UI will update automatically
                case .cancelled:
                    break // User cancelled, just clear loading state
                case .error(let error):
                    print("Apple sign-in failed: \(error.localizedDescription)")
                    // Could show error alert here if needed
                }
            }
        }
    }
}

enum AuthButtonStyle {
    case primary
    case secondary
    case white

    var foregroundColor: Color {
        switch self {
        case .primary:
            return .black
        case .secondary:
            return .white
        case .white:
            return .black
        }
    }

    var backgroundColor: Color {
        switch self {
        case .primary:
            return VivaDesign.Colors.vivaGreen
        case .secondary:
            return .clear
        case .white:
            return .white
        }
    }

    var borderColor: Color {
        switch self {
        case .primary:
            return VivaDesign.Colors.vivaGreen
        case .secondary:
            return .white
        case .white:
            return .white
        }
    }
}

struct AuthButtonView: View {
    let title: String
    let style: AuthButtonStyle
    let image: Image?
    let isLoading: Bool
    let action: () -> Void

    init(
        title: String,
        style: AuthButtonStyle,
        image: Image? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.image = image
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: {
            if !isLoading {
                action()
            }
        }) {
            ZStack {
                // Always present content to maintain layout space
                HStack {
                    if let image = image {
                        image
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(style.foregroundColor)
                    }

                    Text(title)
                        .font(VivaDesign.Typography.body.bold())
                        .foregroundColor(style.foregroundColor)
                }
                .opacity(isLoading ? 0 : 1)
                
                // Loading indicator overlay
                if isLoading {
                    LottieView(animation: .named("bounce_balls_white"))
                        .playing(loopMode: .loop)
                        .frame(width: 30, height: 30)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 36)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(
                    cornerRadius: VivaDesign.Sizing.buttonCornerRadius
                )
                .fill(style.backgroundColor)
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: VivaDesign.Sizing.buttonCornerRadius
                )
                .stroke(
                    style.borderColor,
                    lineWidth: VivaDesign.Sizing.buttonBorderWidth)
            )
        }
        .disabled(isLoading)
    }
}
