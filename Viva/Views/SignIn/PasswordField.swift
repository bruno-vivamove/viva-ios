import SwiftUI

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
