import SwiftUI

struct SignInFormView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authManager: AuthenticationManager
    
    @State private var username = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            ZStack {
                VivaDesign.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: VivaDesign.Spacing.large) {
                    // Form Fields
                    VStack(spacing: VivaDesign.Spacing.medium) {
                        // Username Field
                        TextField("", text: $username)
                            .placeholder(when: username.isEmpty) {
                                Text("Username")
                                    .foregroundColor(VivaDesign.Colors.secondaryText)
                            }
                            .textFieldStyle(VivaTextFieldStyle())
                            .autocapitalization(.none)
                            .textContentType(.username)
                        
                        // Password Field
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
                            
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(VivaDesign.Colors.secondaryText)
                            }
                            .padding(.trailing, VivaDesign.Spacing.medium)
                        }
                        .placeholder(when: password.isEmpty) {
                            Text("Password")
                                .foregroundColor(VivaDesign.Colors.secondaryText)
                        }
                        .textFieldStyle(VivaTextFieldStyle())
                    }
                    .padding(.horizontal, VivaDesign.Spacing.large)
                    
                    if showError {
                        Text("Invalid username or password")
                            .foregroundColor(.red)
                            .font(VivaDesign.Typography.caption)
                    }
                    
                    // Sign In Button
                    AuthButtonView(
                        title: "Sign In",
                        style: .primary,
                        action: signIn
                    )
                    .padding(.horizontal, VivaDesign.Spacing.large)
                    .opacity(isLoading ? 0.5 : 1.0)
                    .disabled(isLoading)
                    
                    if isLoading {
                        ProgressView()
                            .tint(VivaDesign.Colors.vivaGreen)
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
    
    private func signIn() {
        isLoading = true
        showError = false
        
        // Simulate network request
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if username == "test" && password == "test" {
                authManager.signIn()
                dismiss()
            } else {
                showError = true
                isLoading = false
            }
        }
    }
}

// Custom TextField Style
struct VivaTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .foregroundColor(VivaDesign.Colors.primaryText)
            .background(
                RoundedRectangle(cornerRadius: VivaDesign.Sizing.cornerRadius)
                    .stroke(VivaDesign.Colors.divider, lineWidth: VivaDesign.Sizing.borderWidth)
            )
    }
}

// Placeholder View Modifier
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
