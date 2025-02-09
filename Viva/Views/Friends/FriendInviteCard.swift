import SwiftUI

struct FriendInviteCard: View {
    let user: User
    let onAccept: () -> Void
    let onDecline: () -> Void
    private let buttonWidth: CGFloat = 100

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
                VStack(spacing: VivaDesign.Spacing.minimal) {
                    VivaPrimaryButton(
                        title: "Accept",
                        width: buttonWidth,
                        action: onAccept
                    )

                    VivaSecondaryButton(
                        title: "Decline",
                        width: buttonWidth,
                        action: onDecline
                    )
                }
            }
        }
    }
}
