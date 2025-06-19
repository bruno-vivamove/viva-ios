import SwiftUI

struct FriendRequestCard: View {
    @ObservedObject private var viewModel: FriendsViewModel
    let user: UserSummary
    let buttonWidth: CGFloat?
    @Binding var selectedUserId: String?
    
    @State private var showMatchupCreation = false
    @State private var selectedMatchup: Matchup?

    init(viewModel: FriendsViewModel, user: UserSummary, buttonWidth: CGFloat? = nil, selectedUserId: Binding<String?> = .constant(nil)) {
        self.viewModel = viewModel
        self.user = user
        self.buttonWidth = buttonWidth
        self._selectedUserId = selectedUserId
    }
    
    var body: some View {
        // Action button based on friend status
        let action = switch user.friendStatus {
        case .currentUser:
            UserActionCard.UserAction(
                title: "Current User",
                width: buttonWidth,
                variant: .primary
            ) { context in
                // This should not happen
                context.actionCompleted()
            }
            
        case .notFriend, nil:
            UserActionCard.UserAction(
                title: "Add Friend",
                width: buttonWidth,
                variant: .secondary
            ) { context in
                Task {
                    await viewModel.sendFriendRequest(
                        userId: user.id)
                    context.actionCompleted()
                }
            }
            
        case .requestSent:
            UserActionCard.UserAction(
                title: "Cancel",
                width: buttonWidth,
                variant: .secondary
            ) { context in
                Task {
                    await viewModel.cancelFriendRequest(
                        userId: user.id)
                    context.actionCompleted()
                }
            }
            
        case .requestReceived:
            UserActionCard.UserAction(
                title: "Accept Request",
                width: buttonWidth,
                variant: .secondary
            ) { context in
                Task {
                    await viewModel
                        .acceptFriendRequest(
                            userId: user.id)
                    context.actionCompleted()
                }
            }

        case .friend:
            UserActionCard.UserAction(
                title: "Already Friends",
                width: buttonWidth,
                variant: .noAction
            ) { context in
                // No action
                context.actionCompleted()
            }
        }
        
        UserActionCard(
            user: user,
            actions: [action],
            onProfileTap: { userId in
                selectedUserId = userId
            }
        )
        .buttonStyle(PlainButtonStyle())
    }
}
