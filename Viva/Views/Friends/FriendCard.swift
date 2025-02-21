import SwiftUI

struct FriendCard: View {
    let user: User
    
    var body: some View {
        UserActionCard(
            user: user,
            actions: [
                UserActionCard.UserAction(
                    title: "Challenge",
                    width: 100
                ) {
                    // Add challenge action
                }
            ]
        )
    }
}
