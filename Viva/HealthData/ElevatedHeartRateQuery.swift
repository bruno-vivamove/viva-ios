import HealthKit

/// Query implementation for elevated heart rate events
class ElevatedHeartRateQuery: BaseHealthQuery {
    override func execute(
        userId: String,
        startTime: Date,
        currentDayNumber: Int,
        matchupId: String,
        completion: @escaping ([MatchupUserMeasurement]) -> Void
    ) {
        let exerciseType = HKQuantityType.quantityType(
            forIdentifier: .appleExerciseTime)!
        var measurements: [MatchupUserMeasurement] = []
        let queryGroup = DispatchGroup()

        // Query each day separately
        for dayNumber in 0...currentDayNumber {
            queryGroup.enter()
            let (dayStart, dayEnd) = getDayStartEnd(
                startTime: startTime,
                dayNumber: dayNumber
            )

            // Create and execute query for exercise minutes
            let predicate = HKQuery.predicateForSamples(
                withStart: dayStart,
                end: dayEnd,
                options: .strictStartDate
            )
            let query = HKStatisticsQuery(
                quantityType: exerciseType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                defer { queryGroup.leave() }

                if let statistics = statistics,
                   let sum = statistics.sumQuantity() {
                    // Get total minutes of exercise
                    let totalMinutes = Int(sum.doubleValue(for: HKUnit.minute()))
                    
                    let measurement = MatchupUserMeasurement(
                        matchupId: matchupId,
                        dayNumber: dayNumber,
                        measurementType: .elevatedHeartRate,
                        userId: userId,
                        completeDay: dayNumber < currentDayNumber,
                        value: totalMinutes,
                        points: 0
                    )
                    measurements.append(measurement)
                }
            }
            healthStore.execute(query)
        }

        queryGroup.notify(queue: .main) {
            completion(measurements)
        }
    }
}
