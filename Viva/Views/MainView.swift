import Lottie
import SwiftUI

struct MainView: View {
    @EnvironmentObject var userSession: UserSession
    @EnvironmentObject var userProfileService: UserProfileService
    @EnvironmentObject var friendService: FriendService
    @EnvironmentObject var statsService: StatsService
    @EnvironmentObject var matchupService: MatchupService
    @EnvironmentObject var userService: UserService
    @EnvironmentObject var healthKitDataManager: HealthKitDataManager

    private let activeTabColor: Color = VivaDesign.Colors.vivaGreen
    private let inactiveTabColor: UIColor = .white

    init() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()  // Makes it fully opaque
        tabBarAppearance.backgroundColor = UIColor.init(
            VivaDesign.Colors.background
        )

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance  // Applies when scrolled to the bottom
        UITabBar.appearance().unselectedItemTintColor = UIColor.init(
            VivaDesign.Colors.primaryText
        )
    }

    var body: some View {
        TabView {
            // Home Tab
            HomeView(
                viewModel: HomeViewModel(
                    userSession: userSession,
                    matchupService: matchupService
                )
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }

            // Rewards Tab
            RewardsView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tabItem {
                    Image(systemName: "dollarsign.circle.fill")
                    Text("Rewards")
                }

            // Profile Tab
            ProfileView(
                viewModel: ProfileViewModel(
                    userSession: userSession,
                    userService: userService,
                    userProfileService: userProfileService,
                    matchupService: matchupService
                )
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .tabItem {
                Image(systemName: "person.fill")
                Text("Profile")
            }

            // Matchup History Tab
            MatchupHistoryView(
                viewModel: MatchupHistoryViewModel(
                    statsService: statsService,
                    matchupService: matchupService
                )
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .tabItem {
                Image(systemName: "trophy.fill")
                Text("History")
            }

            // Matchups Tab
            FriendsView(
                viewModel: FriendsViewModel(
                    friendService: friendService,
                    userService: userService,
                    userSession: userSession
                )
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .tabItem {
                Image(systemName: "person.2.fill")
                Text("Friends")
            }
        }
        .tint(activeTabColor)
        .onAppear {
            healthKitDataManager.requestAuthorization()
        }
    }
}
