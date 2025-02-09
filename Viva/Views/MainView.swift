import SwiftUI

struct MainView: View {
    private let activeTabColor: Color = .white
    private let inactiveTabColor: UIColor = .lightGray

    private var userSession: UserSession
    private let authenticationManager: AuthenticationManager
    private let userProfileService: UserProfileService
    private let friendService: FriendService
    
    init(userSession: UserSession,
         authenticationManager: AuthenticationManager,
         userProfileService: UserProfileService,
         friendService: FriendService)
    {
        self.userSession = userSession
        self.authenticationManager = authenticationManager
        self.userProfileService = userProfileService
        self.friendService = friendService
    }

    var body: some View {
        TabView {
            // Home Tab
            HomeView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .toolbarBackground(VivaDesign.Colors.background, for: .tabBar)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            // Friends Tab
            FriendsView(friendService: friendService, userSession: userSession)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .toolbarBackground(VivaDesign.Colors.background, for: .tabBar)
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Friends")
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
            MatchupDetailView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .toolbarBackground(VivaDesign.Colors.background, for: .tabBar)
                .tabItem {
                    Image(systemName: "person.3.fill")
                    Text("Matchups")
                }
        }
        .tint(activeTabColor)
//        .onAppear {
//            UITabBar.appearance().unselectedItemTintColor = inactiveTabColor
//        }
    }
}

#Preview {
    let userSession = VivaAppObjects.dummyUserSession()
    let vivaAppObjects = VivaAppObjects(userSession: userSession)

    MainView(
        userSession: userSession,
        authenticationManager: vivaAppObjects.authenticationManager,
        userProfileService: vivaAppObjects.userProfileService,
        friendService: vivaAppObjects.friendService
    )
}
