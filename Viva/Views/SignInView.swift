import Foundation
import Security
import SwiftUI

struct SignInView: View {
    private let logoWidth: CGFloat = 180

    @ObservedObject private var userSession: UserSession
    private let authenticationManager: AuthenticationManager
    private let userProfileService: UserProfileService
    private let friendService: FriendService

    init(userSession: UserSession, authenticationManager: AuthenticationManager, userProfileService: UserProfileService, friendService: FriendService)
    {
        self.userSession = userSession
        self.authenticationManager = authenticationManager
        self.userProfileService = userProfileService
        self.friendService = friendService
    }

    var body: some View {
        ZStack {
            VivaDesign.Colors.background
                .ignoresSafeArea()

            if userSession.isLoggedIn {
                MainView(
                    userSession: userSession,
                    authenticationManager: authenticationManager,
                    userProfileService: userProfileService,
                    friendService: friendService
                )
                .transition(.move(edge: .trailing))
            } else {
                VStack(spacing: VivaDesign.Spacing.medium) {
                    // Logo
                    LogoHeader(width: logoWidth)

                    Spacer()

                    // Main Text
                    MarketingText()

                    Spacer()

                    // Auth Buttons
                    AuthButtonStack(
                        userSession: userSession,
                        authenticationManager: authenticationManager)
                }
                .padding(.vertical, VivaDesign.Spacing.large)
            }
        }
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
    @State private var showSignInForm = false
    @ObservedObject private var userSession: UserSession
    private let authenticationManager: AuthenticationManager

    init(userSession: UserSession, authenticationManager: AuthenticationManager)
    {
        self.userSession = userSession
        self.authenticationManager = authenticationManager
    }

    var body: some View {
        VStack(spacing: VivaDesign.Spacing.small) {
            // Sign Up Button
            AuthButtonView(
                title: "Sign Up",
                style: .primary,
                action: {
                    // Add sign up action
                }
            )

            // Basic Sign In Button
            AuthButtonView(
                title: "Sign In",
                style: .secondary,
                action: {
//                    Task {
//                        await userSession.setTestLoggedIn()
//                    }
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

#Preview {
    let userSession = VivaAppObjects.dummyUserSession()
    let vivaAppObjects = VivaAppObjects(userSession: userSession)

    SignInView(
        userSession: userSession,
        authenticationManager: vivaAppObjects.authenticationManager,
        userProfileService: vivaAppObjects.userProfileService,
        friendService: vivaAppObjects.friendService
    )
}
