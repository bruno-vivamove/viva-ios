import SwiftUI

struct InvitationCard: View {
    private let buttonWidth: CGFloat = 120

    let invite: MatchupInvite
    let userSession: UserSession
    var onAccept: () -> Void
    var onDelete: () -> Void

    var body: some View {
        VivaCard {
            HStack {
                // Action Buttons Container
                VStack(spacing: VivaDesign.Spacing.minimal) {
                    VivaPrimaryButton(
                        title: invite.user?.id == userSession.getUserId() ? "Accept" : "Remind",
                        width: buttonWidth
                    ) {
                        onAccept()
                    }

                    if invite.user?.id != userSession.getUserId() {
                        VivaSecondaryButton(
                            title: "Delete",
                            width: buttonWidth
                        ) {
                            onDelete()
                        }
                    }
                }

                Spacer()

                // User Info
                HStack(spacing: VivaDesign.Spacing.small) {
                    Text(invite.user?.displayName ?? "Open Invite")
                        .foregroundColor(VivaDesign.Colors.vivaGreen)
                        .font(VivaDesign.Typography.caption)

                    VivaProfileImage(
                        imageUrl: invite.user?.imageUrl,
                        size: .small
                    )
                }
            }
        }
    }
}

#Preview {
    InvitationCard(
        invite: MatchupInvite(
            inviteCode: "123",
            matchupId: "match1",
            user: User(id: "usr1", displayName: "Bill Johnson", imageUrl: nil, friendStatus: .friend),
            side: .left,
            createTime: Date()
        ),
        userSession: VivaAppObjects.dummyUserSession(),
        onAccept: {},
        onDelete: {}
    )
}
