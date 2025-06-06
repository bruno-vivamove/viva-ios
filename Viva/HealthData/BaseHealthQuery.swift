import HealthKit

/// Base abstract class with common query functionality
class BaseHealthQuery: HealthDataQuery {
    let healthStore = HKHealthStore()
    
    /// Calculates the start and end dates for a specific day in the matchup
    func getDayStartEnd(
        startTime: Date,
        dayNumber: Int
    ) -> (start: Date, end: Date) {
        let dayLength = 24 * 60 * 60 // seconds in a day
        let dayStart = startTime.addingTimeInterval(
            Double(dayNumber * dayLength))
        let dayEnd = dayStart.addingTimeInterval(Double(dayLength))
        return (dayStart, dayEnd)
    }
    
    func execute(
        userId: String,
        startTime: Date,
        currentDayNumber: Int,
        matchupId: String,
        completion: @escaping ([MatchupUserMeasurement]) -> Void
    ) {
        // Default implementation that does nothing
        // Subclasses should override this method
        AppLogger.warning(
            "BaseHealthQuery execute method called directly. Subclasses should override this method.",
            category: .health
        )
        completion([])
    }
} 