import SwiftUI

struct MatchupInviteCard: View {
    @ObservedObject var coordinator: MatchupInviteCoordinator
    let user: UserSummaryDto
    let matchup: MatchupDetails

    private var isInvited: Bool {
        if let matchup = coordinator.matchup {
            return matchup.invites.contains(where: {$0.user?.id == user.id})
        }
        
        return false
    }

    private var canJoinLeftTeam: Bool {
        coordinator.hasOpenPosition(side: .left)
    }

    private var canJoinRightTeam: Bool {
        coordinator.hasOpenPosition(side: .right)
    }

    var body: some View {
        if isInvited {
            // Invited state with cancel option
            UserActionCard(
                user: user,
                actions: [
                    UserActionCard.UserAction(
                        title: "Cancel Invite",
                        variant: .secondary
                    ) {
                        Task {
                            await coordinator.deleteInvite(
                                userId: user.id,
                                matchupId: matchup.id
                            )
                        }
                    }
                ]
            )
        } else if !canJoinLeftTeam && !canJoinRightTeam {
            // No positions state
            UserActionCard(
                user: user,
                actions: (user.friendStatus == .notFriend ? [
                    UserActionCard.UserAction(
                        title: "Add Friend",
                        variant: .secondary
                    ) {
                        Task {
                            await coordinator.sendFriendRequest(userId: user.id)
                        }
                    }
                ] : [])
            )
        } else {
            // Available positions state with possible Add Friend button
            UserActionCard(
                user: user,
                actions: {
                    var actions: [UserActionCard.UserAction] = []
                    // Add "Add Friend" button if user is not a friend
                    if user.friendStatus == .notFriend {
                        actions.append(
                            UserActionCard.UserAction(
                                title: "Add Friend",
                                variant: .secondary
                            ) {
                                Task {
                                    await coordinator.sendFriendRequest(userId: user.id)
                                }
                            }
                        )
                    }
                    
                    if canJoinLeftTeam, let teamId = coordinator.getTeamId(for: .left) {
                        actions.append(
                            UserActionCard.UserAction(
                                title: "Invite Teammate"
                            ) {
                                Task {
                                    await coordinator.inviteFriend(
                                        userId: user.id,
                                        matchupId: matchup.id,
                                        teamId: teamId
                                    )
                                }
                            }
                        )
                    }
                    
                    if canJoinRightTeam, let teamId = coordinator.getTeamId(for: .right) {
                        actions.append(
                            UserActionCard.UserAction(
                                title: "Invite"
                            ) {
                                Task {
                                    await coordinator.inviteFriend(
                                        userId: user.id,
                                        matchupId: matchup.id,
                                        teamId: teamId
                                    )
                                }
                            }
                        )
                    }
                    return actions
                }()
            )
        }
    }
}
