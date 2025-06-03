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
            // Solid background that fills the entire width
            Rectangle()
                .fill(VivaDesign.Colors.surface)
                .frame(maxWidth: .infinity)

            // Header content with title and optional subtitle
            HStack {
                Text(title)
                    .font(VivaDesign.Typography.titleSmall)
                    .foregroundColor(.white)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(VivaDesign.Typography.caption)
                        .foregroundColor(VivaDesign.Colors.secondaryText)
                }
                
                Spacer()
            }
            .padding(EdgeInsets(
                top: VivaDesign.Spacing.componentSmall,
                leading: VivaDesign.Spacing.componentTiny,
                bottom: VivaDesign.Spacing.componentSmall,
                trailing: VivaDesign.Spacing.componentTiny
            ))
        }
        .listRowInsets(EdgeInsets())
    }
}
