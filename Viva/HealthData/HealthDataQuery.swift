import HealthKit

/// Protocol defining the interface for health data query operations
protocol HealthDataQuery {
    func execute(
        userId: String,
        startTime: Date,
        currentDayNumber: Int,
        matchupId: String,
        completion: @escaping ([MatchupUserMeasurement]) -> Void
    )
} 