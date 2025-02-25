import Foundation
import SwiftUI

struct UserActionCard: View {
    let user: User
    let actions: [UserAction]
    
    enum Style {
        case primary
        case secondary
        case destructive
        case noAction
    }
    
    struct UserAction {
        let title: String
        let action: () -> Void
        let style: Style
        let width: CGFloat?
        
        init(
            title: String,
            width: CGFloat? = nil,
            variant: Style = .primary,
            action: @escaping () -> Void
        ) {
            self.title = title
            self.width = width
            self.style = variant
            self.action = action
        }
    }

    var body: some View {
        VivaCard {
            HStack {
                // User Info
                HStack(spacing: VivaDesign.Spacing.small) {
                    VivaProfileImage(
                        imageUrl: user.imageUrl,
                        size: .small
                    )

                    Text(user.displayName)
                        .foregroundColor(VivaDesign.Colors.primaryText)
                        .font(VivaDesign.Typography.body)
                }

                Spacer()

                // Action Buttons
                HStack(spacing: VivaDesign.Spacing.small) {
                    ForEach(actions, id: \.title) { action in
                        let color = switch action.style {
                        case .primary:
                            VivaDesign.Colors.vivaGreen
                        case .secondary, .noAction:
                            VivaDesign.Colors.primaryText
                        case .destructive:
                            VivaDesign.Colors.destructive
                        }

                        switch action.style {
                        case .primary, .secondary, .destructive:
                            CardButton(
                                title: action.title,
                                width: action.width,
                                color: color
                            ) {
                                action.action()
                            }

                        case .noAction:
                            Text("Already Friends")
                                .foregroundColor(color)
                                .font(VivaDesign.Typography.caption)
                        }
                    }
                }
            }
        }
        .listRowInsets(
            EdgeInsets(
                top: 4,
                leading: 16,
                bottom: 4,
                trailing: 16
            )
        )
        .listRowBackground(Color.clear)
    }
}
