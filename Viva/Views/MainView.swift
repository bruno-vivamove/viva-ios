import SwiftUI

struct MainView: View {
    @EnvironmentObject var userSession: UserSession
    @EnvironmentObject var authenticationManager: AuthenticationManager
    @EnvironmentObject var userProfileService: UserProfileService
    @EnvironmentObject var friendService: FriendService
    @EnvironmentObject var matchupService: MatchupService
    @EnvironmentObject var userService: UserService
    @EnvironmentObject var healthKitDataManager: HealthKitDataManager

    private let activeTabColor: Color = VivaDesign.Colors.vivaGreen
    private let inactiveTabColor: UIColor = .white

    init() {
        UITabBar.appearance().unselectedItemTintColor = .white
    }
    
    var body: some View {
        TabView {
            // Home Tab
            HomeView(
                viewModel: HomeViewModel(
                    userSession: userSession, matchupService: matchupService)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbarBackground(VivaDesign.Colors.background, for: .tabBar)
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }

            // Rewards Tab
            RewardsView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .toolbarBackground(VivaDesign.Colors.background, for: .tabBar)
                .tabItem {
                    Image(systemName: "dollarsign.circle.fill")
                    Text("Rewards")
                }

            // Profile Tab - Updated to use our new ProfileView
            ProfileView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .toolbarBackground(VivaDesign.Colors.background, for: .tabBar)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }

            // Trophies Tab
            TrophiesView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .toolbarBackground(VivaDesign.Colors.background, for: .tabBar)
                .tabItem {
                    Image(systemName: "trophy.fill")
                    Text("Trophies")
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
            .toolbarBackground(VivaDesign.Colors.background, for: .tabBar)
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
