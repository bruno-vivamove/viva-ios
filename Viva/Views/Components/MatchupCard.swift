import SwiftUI

struct MatchupCard: View {
    let matchup: Matchup
    let onCancel: (() -> Void)?

    var body: some View {
        VivaCard {
            HStack {
                // Left User
                HStack(spacing: VivaDesign.Spacing.small) {
                    let user = matchup.leftUsers.first
                    let leftInvite = matchup.invites.first { invite in
                        invite.side == .left
                    }

                    VivaProfileImage(
                        imageUrl: leftInvite?.user?.imageUrl ?? user?.imageUrl,
                        size: .small,
                        isInvited: leftInvite != nil
                    )

                    LabeledValueStack(
                        label: getUserDisplayName(user: user, invite: leftInvite),
                        value: "\(0)",
                        alignment: .leading
                    )
                }

                Spacer()

                // Divider
                Text("|")
                    .foregroundColor(VivaDesign.Colors.secondaryText)
                    .font(VivaDesign.Typography.title3)

                Spacer()

                // Right User
                HStack(spacing: VivaDesign.Spacing.small) {
                    let user = matchup.rightUsers.first
                    let rightInvite = matchup.invites.first { invite in
                        invite.side == .right
                    }

                    LabeledValueStack(
                        label: getUserDisplayName(user: user, invite: rightInvite),
                        value: "\(0)",
                        alignment: .trailing
                    )

                    VivaProfileImage(
                        imageUrl: rightInvite?.user?.imageUrl ?? user?.imageUrl,
                        size: .small,
                        isInvited: rightInvite != nil
                    )
                }
            }
        }
        .background(Color.black)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if matchup.status == .pending {
                Button(role: .destructive) {
                    onCancel?()
                } label: {
                    Text("Cancel")
                }
                .tint(VivaDesign.Colors.destructive)
            }
        }
    }
    
    private func getUserDisplayName(user: User?, invite: MatchupInvite?) -> String {
        if let invite = invite, let invitedUser = invite.user {
            return "\(invitedUser.displayName)"
        } else if let user = user {
            return user.displayName
        } else {
            return "Open Position"
        }
    }
}
