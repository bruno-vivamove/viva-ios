import SwiftUI

struct FriendCard: View {
    let user: User
    let matchupService: MatchupService
    let friendService: FriendService
    let userService: UserService
    let healthKitDataManager: HealthKitDataManager
    let userSession: UserSession
    @State private var showMatchupCreation = false

    var body: some View {
        UserActionCard(
            user: user,
            actions: [
                UserActionCard.UserAction(title: "Challenge") {
                    showMatchupCreation = true
                }
            ]
        )
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showMatchupCreation) {
            MatchupCategoriesView(
                matchupService: matchupService,
                friendService: friendService,
                userService: userService,
                userSession: userSession,
                showCreationFlow: $showMatchupCreation,
                challengedUser: user
            )
        }
    }
}
