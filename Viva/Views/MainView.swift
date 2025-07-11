import Lottie
import SwiftUI

struct MainView: View {
    @EnvironmentObject var userSession: UserSession
    @EnvironmentObject var friendService: FriendService
    @EnvironmentObject var statsService: StatsService
    @EnvironmentObject var matchupService: MatchupService
    @EnvironmentObject var userService: UserService
    @EnvironmentObject var healthKitDataManager: HealthKitDataManager
    @EnvironmentObject var errorManager: ErrorManager

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
        ZStack(alignment: .top) {
            TabView {
                // Home Tab
                NavigationStack {
                    HomeView(
                        viewModel: HomeViewModel(
                            userSession: userSession,
                            matchupService: matchupService
                        )
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

                // Profile Tab
                NavigationStack {
                    if let userId = userSession.userId {
                        ProfileView(
                            userId: userId,
                            userSession: userSession,
                            userService: userService,
                            matchupService: matchupService
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }

                // Matchup History Tab
                NavigationStack {
                    MatchupHistoryView(
                        viewModel: MatchupHistoryViewModel(
                            statsService: statsService,
                            matchupService: matchupService
                        )
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tabItem {
                    Image(systemName: "trophy.fill")
                    Text("History")
                }

                // Matchups Tab
                NavigationStack {
                    FriendsView(
                        viewModel: FriendsViewModel(
                            friendService: friendService,
                            userService: userService,
                            matchupService: matchupService,
                            userSession: userSession
                        )
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Friends")
                }
            }
            .tint(activeTabColor)
            
            // Error banner appears above everything else
            if errorManager.hasErrors {
                ErrorBanner(errorManager: errorManager)
                    .zIndex(100)
            }
        }
    }
}
