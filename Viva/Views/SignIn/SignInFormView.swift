import SwiftUI
import UIKit

class SignInViewModel: ObservableObject {
    @ObservedObject var userSession: UserSession

    @Published var email = ""
    @Published var password = ""
    @Published var showPassword = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Computed property to check if form is valid
    var isFormValid: Bool {
        return isValidEmail(email) && !password.isEmpty
    }

    // Email validation
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email) && !email.isEmpty
    }

    let authManager: AuthenticationManager

    init(authManager: AuthenticationManager, userSession: UserSession) {
        self.authManager = authManager
        self.userSession = userSession
    }

    @MainActor
    func signIn() async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await authManager.signIn(
                email: email, password: password)
            return true
        } catch let errorResponse as AuthErrorResponse {
            // TODO map the error code to user readable messages
            AppLogger.error("Auth Error: " + errorResponse.error.message, category: .auth)
            switch errorResponse.error.message {
            case "MISSING_EMAIL", "INVALID_EMAIL", "INVALID_LOGIN_CREDENTIALS":
                errorMessage = "Invalid email or password."
            default:
                errorMessage = "Error logging in. Please try again."
            }
        } catch let clientError as NetworkClientError {
            // TODO map the error code to user readable messages
            AppLogger.error("Network Client Error: " + clientError.message, category: .network)
            errorMessage = "Error logging in. Please try again."
        } catch {
            AppLogger.error("Unknown Error: " + error.localizedDescription, category: .auth)
            errorMessage = "Error logging in. Please try again."
        }

        isLoading = false
        return false
    }
}

struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}

struct SignInFormView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SignInViewModel
    @FocusState private var focusedField: FormField?
    @State private var showForgotPassword = false
    @State private var passwordResetMessage: String?

    init(authManager: AuthenticationManager, userSession: UserSession) {
        _viewModel = StateObject(
            wrappedValue: SignInViewModel(
                authManager: authManager, userSession: userSession)
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                VisualEffectView(effect: UIBlurEffect(style: .dark))
                    .ignoresSafeArea()
                VivaDesign.Colors.background
                    .opacity(0.30)
                    .ignoresSafeArea()


                // Top decorative elements
                //                TopDesignElement()

                VStack(spacing: VivaDesign.Spacing.large) {
                    // Welcome Text
                    WelcomeSection()
                        .padding(.top, 140)  // Adjust based on design element
                        .padding(.horizontal, VivaDesign.Spacing.large)

                    // Form Fields
                    VStack(spacing: VivaDesign.Spacing.large) {
                        EmailField(
                            email: $viewModel.email, focusedField: $focusedField
                        )
                        PasswordField(
                            password: $viewModel.password,
                            showPassword: $viewModel.showPassword,
                            placeholder: "Password"
                        )

                        // Sign In Button
                        SignInButton(
                            isLoading: viewModel.isLoading,
                            isEnabled: viewModel.isFormValid,
                            action: signIn
                        )

                        // Forgot Password
                        HStack {
                            Spacer()
                            Button("Forgot Password?") {
                                showForgotPassword = true
                            }
                            .foregroundColor(VivaDesign.Colors.vivaGreen)
                            .font(VivaDesign.Typography.caption)
                        }
                    }
                    .padding(.horizontal, VivaDesign.Spacing.large)

                    Spacer()

                    // Error message or password reset success message
                    if let resetMessage = passwordResetMessage {
                        Text(resetMessage)
                            .foregroundColor(VivaDesign.Colors.vivaGreen)
                            .font(VivaDesign.Typography.body)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, VivaDesign.Spacing.large)
                    } else {
                        ErrorMessageView(message: viewModel.errorMessage)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    DismissButton(action: { dismiss() })
                }
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView(authManager: viewModel.authManager, onSuccess: { message in
                    passwordResetMessage = message
                })
                    .presentationBackground(.clear)
            }
        }
    }

    private func signIn() {
        // Explicitly dismiss the keyboard by removing focus
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil,
            for: nil)

        Task {
            if await viewModel.signIn() {
                dismiss()
            }
        }
    }
}

// Updated SignInButton to include isEnabled parameter
struct SignInButton: View {
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        ZStack {
            AuthButtonView(
                title: "Sign In",
                style: .primary,
                action: action
            )
            .opacity(isLoading || !isEnabled ? 0.5 : 1.0)
            .disabled(isLoading || !isEnabled)

            if isLoading {
                ProgressView()
                    .tint(VivaDesign.Colors.vivaGreen)
            }
        }
    }
}

// New Components
struct TopDesignElement: View {
    var body: some View {
        VStack {
            ZStack {
                // Green glow circles
                Circle()
                    .fill(VivaDesign.Colors.vivaGreen)
                    .frame(width: 200, height: 200)
                    .opacity(0.2)
                    .blur(radius: 60)
                    .offset(x: 100, y: -80)

                Circle()
                    .fill(VivaDesign.Colors.vivaGreen)
                    .frame(width: 150, height: 150)
                    .opacity(0.1)
                    .blur(radius: 50)
                    .offset(x: -80, y: 20)
            }
            Spacer()
        }
    }
}

struct WelcomeSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: VivaDesign.Spacing.small) {
            Text("Welcome Back")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(VivaDesign.Colors.primaryText)

            Text("Sign in to continue your fitness journey")
                .font(VivaDesign.Typography.body)
                .foregroundColor(VivaDesign.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ErrorMessageView: View {
    let message: String?

    var body: some View {
        VStack {
            if let message = message {
                Text(message)
                    .foregroundColor(.red)
                    .font(VivaDesign.Typography.caption)
                    .transition(.opacity)
            }
        }
        .frame(height: 20)
        .padding(.horizontal, VivaDesign.Spacing.large)
    }
}

struct DismissButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .foregroundColor(VivaDesign.Colors.primaryText)
        }
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder()
                .padding(.leading, VivaDesign.Spacing.medium)
                .opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
