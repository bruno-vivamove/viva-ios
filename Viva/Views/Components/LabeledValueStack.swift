import SwiftUI

struct LabeledValueStack: View {
    let label: String
    let value: String
    let alignment: HorizontalAlignment

    var body: some View {
        VStack(alignment: alignment) {
            Text(label)
                .foregroundColor(VivaDesign.Colors.vivaGreen)
                .font(VivaDesign.Typography.caption)
                .lineLimit(1)
            Text(value)
                .foregroundColor(VivaDesign.Colors.primaryText)
                .font(VivaDesign.Typography.value)
        }
    }
}
