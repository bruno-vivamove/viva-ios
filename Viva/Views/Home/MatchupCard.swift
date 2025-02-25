import SwiftUI

struct MatchupCard: View {
    let matchup: Matchup
    let onCancel: (() -> Void)?

    var body: some View {
        VivaCard {
            HStack(spacing: 0) {
                // Left side container - aligned to left edge
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
                        label: getUserDisplayName(
                            user: user, invite: leftInvite),
                        value: "\(0)",
                        alignment: .leading
                    )

                    Spacer(minLength: 0)  // Push content to left edge
                }
                .frame(maxWidth: .infinity)

                // Centered divider with fixed width container
                HStack {
                    Text("|")
                        .foregroundColor(VivaDesign.Colors.secondaryText)
                        .font(VivaDesign.Typography.title3)
                }
                .frame(width: 20)  // Fixed width for divider container
                .frame(maxHeight: .infinity)

                // Right side container - aligned to right edge
                HStack(spacing: VivaDesign.Spacing.small) {
                    Spacer(minLength: 0)  // Push content to right edge

                    let user = matchup.rightUsers.first
                    let rightInvite = matchup.invites.first { invite in
                        invite.side == .right
                    }

                    LabeledValueStack(
                        label: getUserDisplayName(
                            user: user, invite: rightInvite),
                        value: "\(0)",
                        alignment: .trailing
                    )

                    VivaProfileImage(
                        imageUrl: rightInvite?.user?.imageUrl ?? user?.imageUrl,
                        size: .small,
                        isInvited: rightInvite != nil
                    )
                }
                .frame(maxWidth: .infinity)
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

    private func getUserDisplayName(user: User?, invite: MatchupInvite?)
        -> String
    {
        if let invite = invite, let invitedUser = invite.user {
            return "\(invitedUser.displayName)"
        } else if let user = user {
            return user.displayName
        } else {
            return "Open"
        }
    }
}
