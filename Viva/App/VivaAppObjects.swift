struct VivaAppObjects {
    public let userSession: UserSession
    public let appNetworkClientSettings: AppNetworkClientSettings
    public let appWithNoSessionNetworkClientSettings:
        AppWithNoSessionNetworkClientSettings
    public let appNetworkClient: NetworkClient<VivaErrorResponse>
    public let appNetworkClientWithNoSession: NetworkClient<VivaErrorResponse>
    public let authenticationManager: AuthenticationManager
    public let authService: AuthService
    public let sessionService: SessionService
    public let userProfileService: UserProfileService
    public let friendService: FriendService
    public let matchupService: MatchupService
    public let userService: UserService
    public let healthService: HealthService
    public let healthKitDataManager: HealthKitDataManager

    init(userSession: UserSession) {
        self.userSession = userSession

        appNetworkClientSettings = AppNetworkClientSettings(
            userSession: userSession)

        appWithNoSessionNetworkClientSettings =
            AppWithNoSessionNetworkClientSettings()

        appNetworkClient = NetworkClient(settings: appNetworkClientSettings)

        appNetworkClientWithNoSession = NetworkClient<VivaErrorResponse>(
            settings: appWithNoSessionNetworkClientSettings)

        authService = AuthService(
            networkClient: NetworkClient<AuthErrorResponse>(
                settings: AuthNetworkClientSettings()))

        sessionService = SessionService(
            networkClient: appNetworkClientWithNoSession)

        userProfileService = UserProfileService(
            networkClient: appNetworkClient,
            userSession: userSession
        )

        friendService = FriendService(
            networkClient: appNetworkClient)

        matchupService = MatchupService(networkClient: appNetworkClient)

        userService = UserService(networkClient: appNetworkClient)

        healthService = HealthService(
            networkClient: appNetworkClientWithNoSession)

        authenticationManager = AuthenticationManager(
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
