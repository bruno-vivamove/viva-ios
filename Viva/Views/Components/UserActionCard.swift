import Foundation
import SwiftUI

struct UserActionCard: View {
    let user: User
    let actions: [UserAction]
    
    struct UserAction {
        let title: String
        let action: () -> Void
        let variant: ButtonVariant
        let width: CGFloat?
        
        enum ButtonVariant {
            case primary
            case secondary
        }
        
        init(
            title: String,
            width: CGFloat? = nil,
            variant: ButtonVariant = .primary,
            action: @escaping () -> Void
        ) {
            self.title = title
            self.width = width
            self.variant = variant
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
                        switch action.variant {
                        case .primary:
                            VivaPrimaryButton(
                                title: action.title,
                                width: action.width
                            ) {
                                action.action()
                            }
                        case .secondary:
                            VivaSecondaryButton(
                                title: action.title,
                                width: action.width
                            ) {
                                action.action()
                            }
                        }
                    }
                }
            }
        }
    }
}
