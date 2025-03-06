import Foundation

class VivaAppObjects: ObservableObject {
    public let userSession: UserSession
    public let authManager: AuthenticationManager
    public let healthKitDataManager: HealthKitDataManager

    public let authNetworkClientSettings: AuthNetworkClientSettings
    public let appNetworkClientSettings: AppNetworkClientSettings
    public let appWithNoSessionNetworkClientSettings:
        AppWithNoSessionNetworkClientSettings

    public let authNetworkClient: NetworkClient<AuthErrorResponse>
    public let appNetworkClient: NetworkClient<VivaErrorResponse>
    public let appNetworkClientWithNoSession: NetworkClient<VivaErrorResponse>
    
    public let authService: AuthService    
    public let sessionService: SessionService
    public let userProfileService: UserProfileService
    public let friendService: FriendService
    public let matchupService: MatchupService
    public let userService: UserService
    public let healthService: HealthService
    

    init() {
        self.userSession = UserSession()

        // Network client settings
        authNetworkClientSettings = AuthNetworkClientSettings()
        appNetworkClientSettings = AppNetworkClientSettings(userSession)
        appWithNoSessionNetworkClientSettings =
            AppWithNoSessionNetworkClientSettings()

        // Network clients
        authNetworkClient = NetworkClient<AuthErrorResponse>(
            settings: authNetworkClientSettings)
        appNetworkClient = NetworkClient(settings: appNetworkClientSettings)
        appNetworkClientWithNoSession = NetworkClient<VivaErrorResponse>(
            settings: appWithNoSessionNetworkClientSettings)

        // Services
        authService = AuthService(networkClient: authNetworkClient)
        sessionService = SessionService(networkClient: appNetworkClientWithNoSession)
        userProfileService = UserProfileService(
            networkClient: appNetworkClient, userSession: userSession)
        friendService = FriendService(
            networkClient: appNetworkClient)
        matchupService = MatchupService(networkClient: appNetworkClient)
        userService = UserService(networkClient: appNetworkClient)
        healthService = HealthService(
            networkClient: appNetworkClientWithNoSession)

        // Other
        authManager = AuthenticationManager(
            userSession: userSession,
            authService: authService,
            sessionService: sessionService,
            userProfileService: userProfileService
        )

        healthKitDataManager = HealthKitDataManager(userSession: userSession)
    }

    public static func dummyUserSession() -> UserSession {
        let userSession = UserSession()
        userSession.setAccessToken("dummy_token")
        userSession.setLoggedIn(
            UserProfile(
                id: "dummy_user_id",
                emailAddress: "dumm_email_address",
                displayName: "dummy_display_name",
                imageUrl: "profile_bruno",
                rewardPoints: 9876,
                streakDays: 10))
        return userSession
    }
}
