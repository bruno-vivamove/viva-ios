import Foundation

class VivaAppObjects: ObservableObject {
    public let userSession: UserSession
    public let authManager: AuthenticationManager
    public let healthKitDataManager: HealthKitDataManager

    public let authNetworkClientSettings: AuthNetworkClientSettings
    public let appNetworkClientSettings: AppNetworkClientSettings
    public let appNetworkClientSettingsNoBodies: AppNetworkClientSettings
    public let appWithNoSessionNetworkClientSettings:
        AppWithNoSessionNetworkClientSettings

    public let authNetworkClient: NetworkClient<AuthErrorResponse>
    public let appNetworkClient: NetworkClient<VivaErrorResponse>
    public let appNetworkClientNoBodies: NetworkClient<VivaErrorResponse>
    public let appNetworkClientWithNoSession: NetworkClient<VivaErrorResponse>

    public let authService: AuthService
    public let sessionService: SessionService
    public let friendService: FriendService
    public let statsService: StatsService
    public let matchupService: MatchupService
    public let userMeasurementService: UserMeasurementService
    public let userService: UserService
    public let healthService: HealthService

    init() {
        userSession = UserSession()

        // Settings with no session
        authNetworkClientSettings = AuthNetworkClientSettings(shouldLogBodies: true)
        appWithNoSessionNetworkClientSettings =
            AppWithNoSessionNetworkClientSettings(shouldLogBodies: true)

        // Clients with no session
        authNetworkClient = NetworkClient<AuthErrorResponse>(
            settings: authNetworkClientSettings)
        appNetworkClientWithNoSession = NetworkClient<VivaErrorResponse>(
            settings: appWithNoSessionNetworkClientSettings)

        // Services with no session
        authService = AuthService(networkClient: authNetworkClient)
        sessionService = SessionService(
            networkClient: appNetworkClientWithNoSession)
        healthService = HealthService(
            networkClient: appNetworkClientWithNoSession)

        // Settings with session
        appNetworkClientSettings = AppNetworkClientSettings(userSession, shouldLogBodies: true)
        appNetworkClientSettingsNoBodies = AppNetworkClientSettings(userSession, shouldLogBodies: false)

        // Client with session
        appNetworkClient = NetworkClient(
            settings: appNetworkClientSettings,
            tokenRefreshHandler: TokenRefreshHandler(
                sessionService: sessionService, userSession: userSession))

        appNetworkClientNoBodies = NetworkClient(
            settings: appNetworkClientSettingsNoBodies,
            tokenRefreshHandler: TokenRefreshHandler(
                sessionService: sessionService, userSession: userSession))

        // Services with session
        friendService = FriendService(
            networkClient: appNetworkClient)
        statsService = StatsService(networkClient: appNetworkClient)
        matchupService = MatchupService(networkClient: appNetworkClientNoBodies)
        userMeasurementService = UserMeasurementService(networkClient: appNetworkClientNoBodies)
        userService = UserService(networkClient: appNetworkClient, userSession: userSession)

        // Other
        authManager = AuthenticationManager(
            userSession: userSession,
            authService: authService,
            sessionService: sessionService
        )

        healthKitDataManager = HealthKitDataManager(userSession: userSession)
    }
}
