import SwiftUI

struct FriendCard: View {
    let user: User
    let matchupService: MatchupService
    let friendService: FriendService
    let userService: UserService
    let healthKitDataManager: HealthKitDataManager
    let userSession: UserSession
    @State private var showMatchupCreation = false
    @State private var selectedMatchup: Matchup?
    
    var body: some View {
        UserActionCard(
            user: user,
            actions: [
                UserActionCard.UserAction(
                    title: "Challenge",
                    width: 100
                ) {
                    showMatchupCreation = true
                }
            ]
        )
        .fullScreenCover(isPresented: $showMatchupCreation) {
            MatchupCategoriesView(
                matchupService: matchupService,
                friendService: friendService,
                userService: userService,
                userSession: userSession,
                showCreationFlow: $showMatchupCreation,
                challengedUser: user
            )
        }
        .sheet(item: $selectedMatchup) { matchup in
            NavigationView {
                MatchupDetailView(
                    matchupService: matchupService,
                    friendService: friendService,
                    userService: userService,
                    userSession: userSession,
                    healthKitDataManager: healthKitDataManager,
                    matchupId: matchup.id
                )
            }
        }
        .onAppear {
            // Observe matchup creation notifications
            NotificationCenter.default.addObserver(
                forName: .matchupCreated,
                object: nil,
                queue: .main
            ) { notification in
                if let matchupId = notification.object as? String {
                    Task {
                        // Get matchup details and open it
                        do {
                            let details = try await matchupService.getMatchup(matchupId: matchupId)
                            await MainActor.run {
                                // Convert MatchupDetails to Matchup
                                selectedMatchup = Matchup(
                                    id: details.id,
                                    matchupHash: details.matchupHash,
                                    displayName: details.displayName,
                                    ownerId: details.ownerId,
                                    createTime: details.createTime,
                                    status: details.status,
                                    startTime: details.startTime,
                                    endTime: details.endTime,
                                    usersPerSide: details.usersPerSide,
                                    lengthInDays: details.lengthInDays,
                                    leftUsers: details.leftUsers,
                                    rightUsers: details.rightUsers,
                                    invites: details.invites
                                )
                            }
                        } catch {
                            print("Error loading matchup: \(error)")
                        }
                    }
                }
            }
        }
    }
}
