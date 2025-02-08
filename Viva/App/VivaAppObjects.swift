struct VivaAppObjects {
    public let userSession: UserSession
    public let appNetworkClientSettings: AppNetworkClientSettings
    public let authenticationManager: AuthenticationManager
    public let authService: AuthService
    public let sessionService: SessionService
    public let userProfileService: UserProfileService
    public let friendService: FriendService

    init(userSession: UserSession) {
        self.userSession = userSession

        appNetworkClientSettings = AppNetworkClientSettings(
            userSession: userSession)

        authService = AuthService(
            networkClient: NetworkClient(
                settings: AuthNetworkClientSettings()))

        sessionService = SessionService(
            networkClient: NetworkClient(
                settings: AppWithNoSessionNetworkClientSettings()))

        userProfileService = UserProfileService(
            networkClient: NetworkClient(settings: appNetworkClientSettings),
            userSession: userSession
        )

        friendService = FriendService(
            networkClient: NetworkClient(settings: appNetworkClientSettings))

        authenticationManager = AuthenticationManager(
            userSession: userSession,
            authService: authService,
            sessionService: sessionService,
            userProfileService: userProfileService
        )
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
                rewardPoints: 9876))
        return userSession
    }
}
