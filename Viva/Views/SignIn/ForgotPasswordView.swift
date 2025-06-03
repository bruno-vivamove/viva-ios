import SwiftUI
import UIKit

class ForgotPasswordViewModel: ObservableObject {
    @Published var email = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // Computed property to check if form is valid
    var isFormValid: Bool {
        return isValidEmail(email)
    }
    
    // Email validation
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email) && !email.isEmpty
    }
    
    let authManager: AuthenticationManager
    
    init(authManager: AuthenticationManager) {
        self.authManager = authManager
    }
    
    @MainActor
    func resetPassword() async -> Bool {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            let _ = try await authManager.resetPassword(email: email)
            successMessage = "Password reset email sent. Please check your inbox."
            return true
        } catch let errorResponse as AuthErrorResponse {
            AppLogger.error("Auth Error: " + errorResponse.error.message, category: .auth)
            switch errorResponse.error.message {
            case "MISSING_EMAIL", "INVALID_EMAIL":
                errorMessage = "Invalid email address."
            case "EMAIL_NOT_FOUND":
                errorMessage = "No account found with this email."
            default:
                errorMessage = "Error sending reset email. Please try again."
            }
        } catch let clientError as NetworkClientError {
            AppLogger.error("Network Client Error: " + clientError.message, category: .network)
            errorMessage = "Network error. Please try again."
        } catch {
            AppLogger.error("Unknown Error: " + error.localizedDescription, category: .auth)
            errorMessage = "Error sending reset email. Please try again."
        }
        
        isLoading = false
        return false
    }
}

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ForgotPasswordViewModel
    @FocusState private var focusedField: FormField?
    var onSuccess: (String) -> Void
    
    init(authManager: AuthenticationManager, onSuccess: @escaping (String) -> Void) {
        _viewModel = StateObject(
            wrappedValue: ForgotPasswordViewModel(
                authManager: authManager)
        )
        self.onSuccess = onSuccess
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
                
                VStack(spacing: VivaDesign.Spacing.large) {
                    // Header Text
                    VStack(alignment: .leading, spacing: VivaDesign.Spacing.small) {
                        Text("Reset Password")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(VivaDesign.Colors.primaryText)
                        
                        Text("Enter your email and we'll send you instructions to reset your password")
                            .font(VivaDesign.Typography.body)
                            .foregroundColor(VivaDesign.Colors.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 140)
                    .padding(.horizontal, VivaDesign.Spacing.large)
                    
                    // Form Fields
                    VStack(spacing: VivaDesign.Spacing.large) {
                        EmailField(
                            email: $viewModel.email, 
                            focusedField: $focusedField
                        )
                        
                        // Reset Password Button
                        VivaButton.primary("Send Reset Link", isLoading: viewModel.isLoading, action: resetPassword)
                            .opacity(viewModel.isFormValid ? 1.0 : 0.5)
                            .disabled(!viewModel.isFormValid)
                    }
                    .padding(.horizontal, VivaDesign.Spacing.large)
                    
                    Spacer()
                    
                    // Error Message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(VivaDesign.Typography.caption)
                            .padding(.horizontal, VivaDesign.Spacing.large)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(VivaDesign.Colors.primaryText)
                    }
                }
            }
        }
    }
    
    private func resetPassword() {
        // Dismiss keyboard
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil,
            for: nil)
        
        Task {
            let success = await viewModel.resetPassword()
            if success, let message = viewModel.successMessage {
                // Pass the success message back to the parent view
                onSuccess(message)
                // Dismiss this view
                dismiss()
            }
        }
    }
}

