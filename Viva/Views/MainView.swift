import SwiftUI

struct MainView: View {
    private let activeTabColor: Color = .white
    private let inactiveTabColor: UIColor = .lightGray

    private var userSession: UserSession
    private let authenticationManager: AuthenticationManager

    init(userSession: UserSession, authenticationManager: AuthenticationManager) {
        self.userSession = userSession
        self.authenticationManager = authenticationManager
    }

    var body: some View {
        TabView {
            // Home Tab
            HomeView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            // Rewards Tab
            RewardsView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .tabItem {
                    Image(systemName: "dollarsign.circle.fill")
                    Text("Rewards")
                }

            // Profile Tab
            ProfileView(
                userSession: userSession, authManager: authenticationManager
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .tabItem {
                Image(systemName: "person.fill")
                Text("Profile")
            }

            // Trophies Tab
            TrophiesView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .tabItem {
                    Image(systemName: "trophy.fill")
                    Text("Trophies")
                }

            // Matchups Tab
            MatchupDetailView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .tabItem {
                    Image(systemName: "person.3.fill")
                    Text("Matchups")
                }
        }
        .tint(activeTabColor)
        .onAppear {
            UITabBar.appearance().unselectedItemTintColor = inactiveTabColor
        }
    }
}

#Preview {
    let userSession = UserSession()
    MainView(
        userSession: userSession,
        authenticationManager: AuthenticationManager(
            userSession: userSession,
            authService: AuthService(
                networkClient: NetworkClient(
                    settings: AuthNetworkClientSettings())),
            sessionService: SessionService(
                networkClient: NetworkClient(
                    settings: AppWithNoSessionNetworkClientSettings())),
            userProfileService: UserProfileService(
                networkClient: NetworkClient(
                    settings: AppNetworkClientSettings(userSession: userSession)
                ),
                userSession: userSession)
        ))
}
