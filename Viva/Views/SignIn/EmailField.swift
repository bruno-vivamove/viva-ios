import SwiftUI

struct EmailField: View {
    @Binding var email: String
    @FocusState.Binding var focusedField: FormField?

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
            .focused($focusedField, equals: .email)
    }
}
