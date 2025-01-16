import SwiftUI

struct InvitationCard: View {
    let invitation: MatchupInvite
    private let buttonWidth: CGFloat = 120

    var body: some View {
        VivaCard {
            HStack {
                // Action Buttons Container
                VStack(spacing: VivaDesign.Spacing.minimal) {
                    VivaPrimaryButton(
                        title: invitation.type == .sent ? "Accept" : "Remind",
                        width: buttonWidth
                    ) {
                        // Add action here

                    }

                    if invitation.type == .sent {
                        VivaSecondaryButton(title: "Delete", width: buttonWidth)
                        {
                            // Add action here
                        }
                    }
                }

                Spacer()

                // User Info
                HStack(spacing: VivaDesign.Spacing.small) {
                    Text(invitation.user.displayName)
                        .foregroundColor(VivaDesign.Colors.vivaGreen)
                        .font(VivaDesign.Typography.caption)

                    VivaProfileImage(
                        imageURL: invitation.user.imageId,
                        size: .small
                    )
                }
            }
        }
    }
}
