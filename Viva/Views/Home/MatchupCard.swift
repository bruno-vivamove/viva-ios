import SwiftUI

struct MatchupCard: View {
    @EnvironmentObject var userSession: UserSession
    @EnvironmentObject var matchupService: MatchupService

    let matchup: Matchup

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
                        value: "\(matchup.leftSidePoints)",
                        alignment: .leading
                    )

                    Spacer(minLength: 0)  // Push content to left edge
                }

                // Centered divider with fixed width container
                HStack {
                    Text("|")
                        .foregroundColor(VivaDesign.Colors.secondaryText)
                        .font(VivaDesign.Typography.title3)
                }
                .frame(width: 20)

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
                        value: "\(matchup.rightSidePoints)",
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
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if matchup.status == .pending {
                if matchup.ownerId == userSession.userId {
                    Button(role: .destructive) {
                        Task {
                            _ = try await matchupService.cancelMatchup(
                                matchupId: matchup.id)
                        }
                    } label: {
                        Text("Cancel")
                    }
                    .tint(VivaDesign.Colors.destructive)
                } else {
                    Button(role: .destructive) {
                        Task {
                            _ = try await matchupService.removeMatchupUser(
                                matchupId: matchup.id,
                                userId: userSession.userId)
                        }
                    } label: {
                        Text("Leave")
                    }
                    .tint(VivaDesign.Colors.warning)
                }
            }
        }
        .listRowBackground(Color.clear)
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
