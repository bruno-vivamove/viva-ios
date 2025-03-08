import SwiftUI

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
