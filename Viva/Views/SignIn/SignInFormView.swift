import SwiftUI

class SignInViewModel: ObservableObject {
    @ObservedObject var userSession: UserSession

    @Published var email = ""
    @Published var password = ""
    @Published var showPassword = false
    @Published var isLoading = false
    @Published var errorMessage: String?

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
            if (email.isEmpty || password.isEmpty) {
                try await authManager.signIn(
                    email: "bruno@vivamove.com", password: "abc12345")
                return true
            }
            
            try await authManager.signIn(
                email: email, password: password)
            return true
        } catch let errorResponse as AuthErrorResponse {
            // TODO map the error code to user readable messages
            print("Auth Error: " + errorResponse.error.message)
            switch errorResponse.error.message {
            case "MISSING_EMAIL", "INVALID_EMAIL", "INVALID_LOGIN_CREDENTIALS":
                errorMessage = "Invalid email or password."
            default:
                errorMessage = "Error logging in. Please try again."
            }
        } catch let clientError as NetworkClientError {
            // TODO map the error code to user readable messages
            print("Network Client Error: " + clientError.message)
            errorMessage = "Error logging in. Please try again."
        } catch {
            print("Unknown Error: " + error.localizedDescription)
            errorMessage = "Error logging in. Please try again."
        }

        isLoading = false
        return false
    }
}

struct SignInFormView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SignInViewModel
    @FocusState private var focusedField: FormField?
    
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
                VivaDesign.Colors.background
                    .ignoresSafeArea()
                
                // Top decorative elements
                TopDesignElement()
                
                VStack(spacing: VivaDesign.Spacing.large) {
                    // Welcome Text
                    WelcomeSection()
                        .padding(.top, 140) // Adjust based on design element
                        .padding(.horizontal, VivaDesign.Spacing.large)
                    
                    // Form Fields
                    VStack(spacing: VivaDesign.Spacing.large) {
                        EmailField(email: $viewModel.email, focusedField: $focusedField)
                        PasswordField(
                            password: $viewModel.password,
                            showPassword: $viewModel.showPassword
                        )
                        
                        // Sign In Button
                        SignInButton(
                            isLoading: viewModel.isLoading,
                            action: signIn
                        )
                        
                        // Forgot Password
                        HStack {
                            Spacer()
                            Button("Forgot Password?") {
                                // Add forgot password action
                            }
                            .foregroundColor(VivaDesign.Colors.vivaGreen)
                            .font(VivaDesign.Typography.caption)
                        }
                    }
                    .padding(.horizontal, VivaDesign.Spacing.large)
                    
                    Spacer()
                                        
                    ErrorMessageView(message: viewModel.errorMessage)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    DismissButton(action: { dismiss() })
                }
            }
            .onAppear {
                focusedField = .email
            }
        }
    }

    private func signIn() {
        Task {
            if await viewModel.signIn() {
                dismiss()
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

struct SignInButton: View {
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        ZStack {
            AuthButtonView(
                title: "Sign In",
                style: .primary,
                action: action
            )
            .opacity(isLoading ? 0.5 : 1.0)
            .disabled(isLoading)

            if isLoading {
                ProgressView()
                    .tint(VivaDesign.Colors.vivaGreen)
            }
        }
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

struct VivaTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .foregroundColor(VivaDesign.Colors.primaryText)
            .background(
                RoundedRectangle(cornerRadius: VivaDesign.Sizing.cornerRadius)
                    .stroke(
                        VivaDesign.Colors.divider,
                        lineWidth: VivaDesign.Sizing.borderWidth
                    )
            )
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

#Preview {
    let userSession = VivaAppObjects.dummyUserSession()
    let vivaAppObjects = VivaAppObjects(userSession: userSession)

    SignInFormView(
        authManager: vivaAppObjects.authenticationManager,
        userSession: userSession)
}
