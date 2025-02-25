import SwiftUI

struct MainView: View {
    private let activeTabColor: Color = .white
    private let inactiveTabColor: UIColor = .lightGray

    private let userSession: UserSession
    private let authenticationManager: AuthenticationManager
    private let userProfileService: UserProfileService
    private let friendService: FriendService
    private let matchupService: MatchupService
    private let userService: UserService
    private let healthKitDataManager: HealthKitDataManager

    init(
        userSession: UserSession,
        authenticationManager: AuthenticationManager,
        userProfileService: UserProfileService,
        friendService: FriendService,
        matchupService: MatchupService,
        userService: UserService,
        healthKitDataManager: HealthKitDataManager
    ) {
        self.userSession = userSession
        self.authenticationManager = authenticationManager
        self.userProfileService = userProfileService
        self.friendService = friendService
        self.matchupService = matchupService
        self.userService = userService
        self.healthKitDataManager = healthKitDataManager
    }

    var body: some View {
        TabView {
            // Home Tab
            HomeView(
                matchupService: matchupService, userSession: userSession,
                friendService: friendService,
                userService: userService,
                healthKitDataManager: healthKitDataManager
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
                    Image(systemName: "person.2.fill")
                    Text("Rewards")
                }

            // Profile Tab
            ProfileView(
                userSession: userSession,
                authManager: authenticationManager,
                userProfileService: userProfileService
            )
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
                matchupService: matchupService, friendService: friendService,
                userService: userService,
                healthKitDataManager: healthKitDataManager,
                userSession: userSession
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

#Preview {
    let userSession = VivaAppObjects.dummyUserSession()
    let vivaAppObjects = VivaAppObjects(userSession: userSession)

    MainView(
        userSession: userSession,
        authenticationManager: vivaAppObjects.authenticationManager,
        userProfileService: vivaAppObjects.userProfileService,
        friendService: vivaAppObjects.friendService,
        matchupService: vivaAppObjects.matchupService,
        userService: vivaAppObjects.userService,
        healthKitDataManager: vivaAppObjects.healthKitDataManager
    )
}
