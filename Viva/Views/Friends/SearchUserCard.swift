import SwiftUI

struct SearchUserCard: View {
    let user: User
    let onSendRequest: () -> Void
    let onCancelRequest: () -> Void
    private let buttonWidth: CGFloat = 120
    
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
                
                // Action button based on friend status
                switch user.friendStatus {
                case .notFriend, nil:
                    VivaPrimaryButton(
                        title: "Add Friend",
                        width: buttonWidth,
                        action: onSendRequest
                    )
                    .accessibilityLabel("Add \(user.displayName) as friend")
                    
                case .requestSent:
                    VivaSecondaryButton(
                        title: "Cancel Request",
                        width: buttonWidth,
                        action: onCancelRequest
                    )
                    .accessibilityLabel("Cancel friend request to \(user.displayName)")
                    
                case .requestReceived:
                    Text("Respond to Request")
                        .foregroundColor(VivaDesign.Colors.secondaryText)
                        .font(VivaDesign.Typography.caption)
                    
                case .friend:
                    Text("Already Friends")
                        .foregroundColor(VivaDesign.Colors.secondaryText)
                        .font(VivaDesign.Typography.caption)
                }
            }
        }
    }
}
