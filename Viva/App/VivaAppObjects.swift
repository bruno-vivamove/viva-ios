import Foundation

class VivaAppObjects: ObservableObject {
    public let userSession: UserSession
    public let authManager: AuthenticationManager
    public let healthKitDataManager: HealthKitDataManager
    public let backgroundTaskManager: BackgroundTaskManager
    public let errorManager: ErrorManager

    public let appNetworkClient: NetworkClient<VivaErrorResponse>
    public let appNetworkClientNoBodies: NetworkClient<VivaErrorResponse>

    public let authService: AuthService
    public let sessionService: SessionService
    public let friendService: FriendService
    public let statsService: StatsService
    public let matchupService: MatchupService
    public let userMeasurementService: UserMeasurementService
    public let workoutService: WorkoutService
    public let userService: UserService
    public let healthService: HealthService
    public let backgroundHealthSyncManager: BackgroundHealthSyncManager
    public let backgroundMatchupRefreshManager: BackgroundMatchupRefreshManager
    public let deviceTokenService: DeviceTokenService

    init() {
        userSession = UserSession()
        errorManager = ErrorManager()

        // Services with no session
        authService = AuthService(
            networkClient: NetworkClient<AuthErrorResponse>(
                settings: AuthNetworkClientSettings(shouldLogBodies: false),
                errorManager: errorManager
            )
        )

        sessionService = SessionService(
            networkClient: NetworkClient<VivaErrorResponse>(
                settings: AppWithNoSessionNetworkClientSettings(
                    shouldLogBodies: false
                ),
                errorManager: errorManager
            )
        )

        healthService = HealthService(
            networkClient: NetworkClient<VivaErrorResponse>(
                settings: AppWithNoSessionNetworkClientSettings(
                    shouldLogBodies: false,
                    maxRetries: 0
                ),
                errorManager: errorManager,
            )
        )

        // Services with session
        appNetworkClient = NetworkClient(
            settings: AppNetworkClientSettings(
                userSession,
                shouldLogBodies: true
            ),
            tokenRefreshHandler: TokenRefreshHandler(
                sessionService: sessionService,
                userSession: userSession
            ),
            errorManager: errorManager
        )
        appNetworkClientNoBodies = NetworkClient(
            settings: AppNetworkClientSettings(
                userSession,
                shouldLogBodies: false
            ),
            tokenRefreshHandler: TokenRefreshHandler(
                sessionService: sessionService,
                userSession: userSession
            ),
            errorManager: errorManager
        )

        friendService = FriendService(
            networkClient: appNetworkClientNoBodies
        )
        statsService = StatsService(networkClient: appNetworkClientNoBodies)
        matchupService = MatchupService(networkClient: appNetworkClientNoBodies)
        userMeasurementService = UserMeasurementService(
            networkClient: appNetworkClientNoBodies
        )
        workoutService = WorkoutService(networkClient: appNetworkClientNoBodies)
        userService = UserService(
            networkClient: appNetworkClientNoBodies,
            userSession: userSession
        )
        deviceTokenService = DeviceTokenService(
            networkClient: appNetworkClientNoBodies,
            userSession: userSession
        )

        // Other
        authManager = AuthenticationManager(
            userSession: userSession,
            authService: authService,
            sessionService: sessionService,
            deviceTokenService: deviceTokenService
        )

        // Initialize HealthKitDataManager with UserMeasurementService
        healthKitDataManager = HealthKitDataManager(
            userSession: userSession,
            userMeasurementService: userMeasurementService,
            workoutService: workoutService,
            matchupService: matchupService,
            errorManager: errorManager
        )

        // Initialize BackgroundTaskManager with HealthKitDataManager dependency
        backgroundTaskManager = BackgroundTaskManager(
            healthKitDataManager: healthKitDataManager
        )

        // Initialize BackgroundHealthSyncManager
        backgroundHealthSyncManager = BackgroundHealthSyncManager(
            matchupService: matchupService,
            healthKitDataManager: healthKitDataManager,
            userMeasurementService: userMeasurementService,
            userSession: userSession
        )

        // Initialize BackgroundMatchupRefreshManager
        backgroundMatchupRefreshManager = BackgroundMatchupRefreshManager(
            matchupService: matchupService,
            userSession: userSession
        )

        // Configure ErrorManager with HealthService for connectivity monitoring
        errorManager.setHealthService(healthService)
    }
}
