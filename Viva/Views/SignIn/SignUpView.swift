import SwiftUI
import UIKit
import GoogleSignIn

class SignUpViewModel: ObservableObject {
    @ObservedObject var userSession: UserSession
    
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var showPassword = false
    @Published var showConfirmPassword = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var loadingStates: [String: Bool] = [:]
    
    // Computed property to check if form is valid
    var isFormValid: Bool {
        return isValidEmail(email) && isValidPassword(password) && password == confirmPassword
    }
    
    // Email validation
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email) && !email.isEmpty
    }
    
    // Password validation (minimum 8 characters)
    private func isValidPassword(_ password: String) -> Bool {
        return password.count >= 8
    }
    
    let authManager: AuthenticationManager
    
    init(authManager: AuthenticationManager, userSession: UserSession) {
        self.authManager = authManager
        self.userSession = userSession
    }
    
    @MainActor
    func signUp() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        // Validate passwords match
        if password != confirmPassword {
            errorMessage = "Passwords do not match."
            isLoading = false
            return false
        }
        
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
    
    func executeGoogleSignIn() {
        let actionId = "Continue with Google"
        loadingStates[actionId] = true
        
        authManager.signInWithGoogle { result in
            DispatchQueue.main.async {
                self.loadingStates[actionId] = false
                
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
    
    func executeAppleSignIn() {
        let actionId = "Continue with Apple"
        loadingStates[actionId] = true
        
        authManager.signInWithApple { result in
            DispatchQueue.main.async {
                self.loadingStates[actionId] = false
                
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
        // Custom layout approach without NavigationStack
        ZStack {
            // Background
            VisualEffectView(effect: UIBlurEffect(style: .dark))
                .ignoresSafeArea()
            VivaDesign.Colors.background
                .opacity(0.30)
                .ignoresSafeArea()

            // Main content
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
                                showPassword: $viewModel.showPassword,
                                placeholder: "Password"
                            )
                            
                            PasswordField(
                                password: $viewModel.confirmPassword,
                                showPassword: $viewModel.showConfirmPassword,
                                placeholder: "Confirm Password"
                            )
                            
                            Text("Minimum of 8 characters")
                                .font(.system(size: 12))
                                .foregroundColor(VivaDesign.Colors.secondaryText)
                        }
                        
                        // Sign Up Button
                        VivaButton(
                            title: "Sign Up",
                            style: .primary,
                            isLoading: viewModel.isLoading,
                            action: signUp
                        )
                        .opacity(viewModel.isFormValid ? 1.0 : 0.5)
                        .disabled(!viewModel.isFormValid)

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
                            VivaButton(
                                title: "Continue with Google",
                                style: .secondary,
                                image: Image("google_logo"),
                                isLoading: viewModel.loadingStates["Continue with Google"] ?? false
                            ) {
                                viewModel.executeGoogleSignIn()
                            }
                            
                            VivaButton(
                                title: "Continue with Apple",
                                style: .white,
                                image: Image(systemName: "applelogo"),
                                isLoading: viewModel.loadingStates["Continue with Apple"] ?? false
                            ) {
                                viewModel.executeAppleSignIn()
                            }
                        }
                    }
                    
                    // Error Message
                    ErrorMessageView(message: viewModel.errorMessage)
                }
                .padding(VivaDesign.Spacing.large)
            }
            
            // Custom transparent navigation bar overlay
            VStack {
                // Custom navigation bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(VivaDesign.Colors.primaryText)
                            .padding(8)
                            .background(Color.black.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 16)
                    
                    Spacer()
                }
                .frame(height: 44)
                .background(Color.clear)
                
                Spacer()
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .edgesIgnoringSafeArea(.top) // Extend to top edge
    }
    
    private func signUp() {
        // Explicitly dismiss the keyboard by removing focus
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        Task {
            if await viewModel.signUp() {
                dismiss()
            }
        }
    }
}
