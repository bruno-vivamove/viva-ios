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
            ) {
                // This should not happen
            }
            
        case .notFriend, nil:
            UserActionCard.UserAction(
                title: "Add Friend",
                width: buttonWidth,
                variant: .primary
            ) {
                Task {
                    await viewModel.sendFriendRequest(
                        userId: user.id)
                }
            }
            
        case .requestSent:
            UserActionCard.UserAction(
                title: "Cancel",
                width: buttonWidth,
                variant: .secondary
            ) {
                Task {
                    Task {
                        await viewModel.cancelFriendRequest(
                            userId: user.id)
                    }
                }
            }
            
        case .requestReceived:
            UserActionCard.UserAction(
                title: "Accept Request",
                width: buttonWidth,
                variant: .primary
            ) {
                Task {
                    await viewModel
                        .acceptFriendRequest(
                            userId: user.id)
                }
            }

        case .friend:
            UserActionCard.UserAction(
                title: "Already Friends",
                width: buttonWidth,
                variant: .noAction
            ) {
                // No action
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
