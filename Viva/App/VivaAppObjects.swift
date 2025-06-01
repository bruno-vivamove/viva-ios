import Foundation

class VivaAppObjects: ObservableObject {
    public let userSession: UserSession
    public let authManager: AuthenticationManager
    public let healthKitDataManager: HealthKitDataManager
    public let errorManager: ErrorManager

    public let networkClientSettingsForAuth: AuthNetworkClientSettings
    public let networkClientSettings: AppNetworkClientSettings
    public let networkClientSettingsNoBodies: AppNetworkClientSettings
    public let networkClientSettingsWithNoSession:
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
    public let workoutService: WorkoutService
    public let userService: UserService
    public let healthService: HealthService

    init() {
        userSession = UserSession()
        errorManager = ErrorManager()

        // Network Client Settings
        networkClientSettingsForAuth = AuthNetworkClientSettings(
            shouldLogBodies: false
        )
        networkClientSettingsWithNoSession =
            AppWithNoSessionNetworkClientSettings(shouldLogBodies: false)
        networkClientSettings = AppNetworkClientSettings(
            userSession,
            shouldLogBodies: true
        )
        networkClientSettingsNoBodies = AppNetworkClientSettings(
            userSession,
            shouldLogBodies: false
        )

        // Services with no session
        authNetworkClient = NetworkClient<AuthErrorResponse>(
            settings: networkClientSettingsForAuth,
            errorManager: errorManager
        )
        appNetworkClientWithNoSession = NetworkClient<VivaErrorResponse>(
            settings: networkClientSettingsWithNoSession,
            errorManager: errorManager
        )

        authService = AuthService(networkClient: authNetworkClient)
        sessionService = SessionService(
            networkClient: appNetworkClientWithNoSession
        )
        healthService = HealthService(
            networkClient: appNetworkClientWithNoSession
        )

        // Services with Session
        appNetworkClient = NetworkClient(
            settings: networkClientSettings,
            tokenRefreshHandler: TokenRefreshHandler(
                sessionService: sessionService,
                userSession: userSession
            ),
            errorManager: errorManager
        )
        appNetworkClientNoBodies = NetworkClient(
            settings: networkClientSettingsNoBodies,
            tokenRefreshHandler: TokenRefreshHandler(
                sessionService: sessionService,
                userSession: userSession
            ),
            errorManager: errorManager
        )
        friendService = FriendService(
            networkClient: appNetworkClient
        )
        statsService = StatsService(networkClient: appNetworkClient)
        matchupService = MatchupService(networkClient: appNetworkClient)
        userMeasurementService = UserMeasurementService(
            networkClient: appNetworkClientNoBodies
        )
        workoutService = WorkoutService(networkClient: appNetworkClient)
        userService = UserService(
            networkClient: appNetworkClient,
            userSession: userSession
        )

        // Other
        authManager = AuthenticationManager(
            userSession: userSession,
            authService: authService,
            sessionService: sessionService
        )

        // Initialize HealthKitDataManager with UserMeasurementService
        healthKitDataManager = HealthKitDataManager(
            userSession: userSession,
            userMeasurementService: userMeasurementService,
            workoutService: workoutService,
            matchupService: matchupService
        )

        // Configure ErrorManager with HealthService for connectivity monitoring
        errorManager.setHealthService(healthService)
    }
}
