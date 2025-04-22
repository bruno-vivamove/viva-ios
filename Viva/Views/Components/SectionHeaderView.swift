import SwiftUI

struct SectionHeaderView: View {
    let title: String
    let subtitle: String?
    
    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        ZStack {
            // Solid black background that fills the entire width
            Rectangle()
                .fill(Color.black)
                .frame(maxWidth: .infinity)

            // Header content with title and optional subtitle
            HStack {
                Text(title)
                    .font(VivaDesign.Typography.header)
                    .foregroundColor(.white)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(VivaDesign.Typography.caption)
                        .foregroundColor(VivaDesign.Colors.secondaryText)
                }
                
                Spacer()
            }
            .padding(EdgeInsets(
                top: VivaDesign.Spacing.small,
                leading: VivaDesign.Spacing.xsmall,
                bottom: VivaDesign.Spacing.small,
                trailing: VivaDesign.Spacing.xsmall
            ))
        }
        .listRowInsets(EdgeInsets())
    }
}
