import SwiftUI

class SignInViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var showPassword = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authService: AuthService
    private let authManager: AuthenticationManager

    init(
        authService: AuthService = AuthService(),
        authManager: AuthenticationManager
    ) {
        self.authService = authService
        self.authManager = authManager
    }

    @MainActor
    func signIn() async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let authResponse = try await authService.signIn(
                email: email, password: password)
            authManager.signIn()
            return true
        } catch let clientError as ClientError {
            if let message = clientError.message {
                errorMessage = message
            } else {
                errorMessage = "Error logging in. Please try again.."
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
        return false
    }
}

struct SignInFormView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SignInViewModel

    init(authManager: AuthenticationManager) {
        _viewModel = StateObject(
            wrappedValue: SignInViewModel(authManager: authManager)
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VivaDesign.Colors.background
                    .ignoresSafeArea()

                VStack(spacing: VivaDesign.Spacing.large) {
                    EmailField(email: $viewModel.email)
                    PasswordField(
                        password: $viewModel.password,
                        showPassword: $viewModel.showPassword
                    )
                    SignInButton(
                        isLoading: viewModel.isLoading,
                        action: signIn
                    )
                    ErrorMessageView(message: viewModel.errorMessage)
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

    private func signIn() {
        Task {
            if await viewModel.signIn() {
                dismiss()
            }
        }
    }
}

struct EmailField: View {
    @Binding var email: String

    var body: some View {
        TextField("", text: $email)
            .placeholder(when: email.isEmpty) {
                Text("Email")
                    .foregroundColor(VivaDesign.Colors.secondaryText)
            }
            .textFieldStyle(VivaTextFieldStyle())
            .autocapitalization(.none)
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .padding(.horizontal, VivaDesign.Spacing.large)
    }
}

struct PasswordField: View {
    @Binding var password: String
    @Binding var showPassword: Bool

    var body: some View {
        ZStack(alignment: .trailing) {
            Group {
                if showPassword {
                    TextField("", text: $password)
                } else {
                    SecureField("", text: $password)
                }
            }
            .textContentType(.password)
            .autocapitalization(.none)
            .placeholder(when: password.isEmpty) {
                Text("Password")
                    .foregroundColor(VivaDesign.Colors.secondaryText)
            }

            PasswordVisibilityToggle(showPassword: $showPassword)
        }
        .textFieldStyle(VivaTextFieldStyle())
        .padding(.horizontal, VivaDesign.Spacing.large)
    }
}

struct PasswordVisibilityToggle: View {
    @Binding var showPassword: Bool

    var body: some View {
        Button(action: { showPassword.toggle() }) {
            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                .foregroundColor(VivaDesign.Colors.secondaryText)
        }
        .padding(.trailing, VivaDesign.Spacing.medium)
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
        .padding(.horizontal, VivaDesign.Spacing.large)
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
    SignInFormView(authManager: AuthenticationManager())
}
