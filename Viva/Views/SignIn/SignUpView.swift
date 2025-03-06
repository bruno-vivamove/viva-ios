import SwiftUI

class SignUpViewModel: ObservableObject {
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
    func signUp() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authManager.signUp(email: email, password: password)
            return true
        } catch let errorResponse as AuthErrorResponse {
            switch errorResponse.error.message {
            case "EMAIL_EXISTS":
                errorMessage = "This email is already registered."
            case "INVALID_EMAIL":
                errorMessage = "Please enter a valid email address."
            case "WEAK_PASSWORD":
                errorMessage = "Password must be at least 8 characters."
            default:
                errorMessage = "Error creating account. Please try again."
            }
        } catch {
            errorMessage = "Error creating account. Please try again."
        }
        
        isLoading = false
        return false
    }
}

struct SignUpFormView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SignUpViewModel
    @FocusState private var focusedField: FormField?
    
    init(authManager: AuthenticationManager, userSession: UserSession) {
        _viewModel = StateObject(
            wrappedValue: SignUpViewModel(
                authManager: authManager,
                userSession: userSession
            )
        )
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                VivaDesign.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: VivaDesign.Spacing.large) {
                        // Logo
                        HStack {
                            Spacer()
                            Image("viva_logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)

                        // Create Account Header
                        Text("Create Account")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(VivaDesign.Colors.primaryText)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        // Form Fields
                        VStack(spacing: VivaDesign.Spacing.medium) {
                            // Email Field
                            EmailField(
                                email: $viewModel.email,
                                focusedField: $focusedField
                            )
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: VivaDesign.Spacing.xsmall) {
                                PasswordField(
                                    password: $viewModel.password,
                                    showPassword: $viewModel.showPassword
                                )
                                
                                Text("Minimum of 8 characters")
                                    .font(.system(size: 12))
                                    .foregroundColor(VivaDesign.Colors.secondaryText)
                            }
                            
                            // Sign Up Button
                            SignUpButton(
                                isLoading: viewModel.isLoading,
                                action: signUp
                            )
                            
                            // Terms Text with interactive links
                            LegalLinksView()
                            
                            // Divider
                            HStack {
                                VivaDivider()
                                Text("or")
                                    .foregroundColor(VivaDesign.Colors.secondaryText)
                                    .font(VivaDesign.Typography.caption)
                                VivaDivider()
                            }
                            
                            // Social Buttons
                            VStack(spacing: VivaDesign.Spacing.medium) {
                                AuthButtonView(
                                    title: "Continue with Google",
                                    style: .secondary,
                                    image: Image("google_logo"),
                                    action: {
                                        // Add Google sign up action
                                    }
                                )
                                
                                AuthButtonView(
                                    title: "Continue with Apple",
                                    style: .white,
                                    image: Image(systemName: "applelogo"),
                                    action: {
                                        // Add Apple sign up action
                                    }
                                )
                            }
                        }
                        
                        // Error Message
                        ErrorMessageView(message: viewModel.errorMessage)
                    }
                    .padding(VivaDesign.Spacing.large)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    DismissButton(action: { dismiss() })
                }
            }
        }
    }
    
    private func signUp() {
        Task {
            if await viewModel.signUp() {
                dismiss()
            }
        }
    }
}

struct SignUpButton: View {
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        ZStack {
            AuthButtonView(
                title: "Sign Up",
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
