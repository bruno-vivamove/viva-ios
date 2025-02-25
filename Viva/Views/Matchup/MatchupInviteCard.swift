import SwiftUI

struct MatchupInviteCard: View {
    @ObservedObject var coordinator: MatchupInviteCoordinator
    let user: User
    let usersPerSide: Int
    let onInvite: ((MatchupUser.Side?) -> Void)
    let onCancel: () -> Void
    let onInviteSent: (() -> Void)? = nil

    private var isInvited: Bool {
        coordinator.invitedFriends.contains(user.id)
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
                        onCancel()
                    }
                ]
            )
        } else if !canJoinLeftTeam && !canJoinRightTeam {
            // No positions state
            UserActionCard(
                user: user,
                actions: [
                    UserActionCard.UserAction(
                        title: "No Open Positions",
                        variant: .secondary
                    ) {
                        // No action, just showing status
                    }
                ] + (user.friendStatus == .notFriend ? [
                    UserActionCard.UserAction(
                        title: "Add Friend",
                        variant: .primary
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
                    
                    if canJoinLeftTeam {
                        actions.append(
                            UserActionCard.UserAction(
                                title: "Invite Teammate"
                            ) {
                                onInvite(.left)
                                onInviteSent?()
                            }
                        )
                    }
                    
                    if canJoinRightTeam {
                        actions.append(
                            UserActionCard.UserAction(
                                title: "Invite"
                            ) {
                                onInvite(.right)
                                onInviteSent?()
                            }
                        )
                    }
                    return actions
                }()
            )
        }
    }
}

#Preview {
    EmptyView()
}
