import Foundation
import Security
import SwiftUI

import Foundation
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

    var body: some View {
        VStack(spacing: VivaDesign.Spacing.small) {
            // Sign Up Button
            AuthButtonView(
                title: "Sign Up",
                style: .primary,
                action: {
                    showSignUpForm = true
                }
            )

            // Basic Sign In Button
            AuthButtonView(
                title: "Sign In",
                style: .secondary,
                action: {
                    showSignInForm = true
                }
            )

            // Google Sign In Button
            AuthButtonView(
                title: "Sign In with Google",
                style: .secondary,
                image: Image("google_logo"),
                action: {
                    // Add Google sign in action
                }
            )

            // Apple Sign In Button
            AuthButtonView(
                title: "Sign in with Apple",
                style: .white,
                image: Image(systemName: "applelogo"),
                action: {
                    // Add Apple sign in action
                }
            )
        }
        .padding(.horizontal, VivaDesign.Spacing.large)
        .sheet(isPresented: $showSignInForm) {
            SignInFormView(
                authManager: authenticationManager, userSession: userSession)
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
    let action: () -> Void

    init(
        title: String,
        style: AuthButtonStyle,
        image: Image? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.image = image
        self.action = action
    }

    var body: some View {
        Button(action: action) {
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
            .frame(maxWidth: .infinity)
            .padding()
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
    }
}
