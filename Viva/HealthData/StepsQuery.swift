import HealthKit

/// Query implementation for step count data
class StepsQuery: BaseHealthQuery {
    override func execute(
        userId: String,
        startTime: Date,
        currentDayNumber: Int,
        matchupId: String,
        completion: @escaping ([MatchupUserMeasurement]) -> Void
    ) {
        let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        var measurements: [MatchupUserMeasurement] = []
        let queryGroup = DispatchGroup()

        // Query each day separately
        for dayNumber in 0...currentDayNumber {
            queryGroup.enter()
            let (dayStart, dayEnd) = getDayStartEnd(
                startTime: startTime,
                dayNumber: dayNumber
            )

            // Create and execute query for daily step count
            let predicate = HKQuery.predicateForSamples(
                withStart: dayStart,
                end: dayEnd,
                options: .strictStartDate
            )
            let query = HKStatisticsQuery(
                quantityType: stepsType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                defer { queryGroup.leave() }

                if let sum = result?.sumQuantity() {
                    let steps = Int(sum.doubleValue(for: HKUnit.count()))
                    let measurement = MatchupUserMeasurement(
                        matchupId: matchupId,
                        dayNumber: dayNumber,
                        measurementType: .steps,
                        userId: userId,
                        completeDay: dayNumber < currentDayNumber,
                        value: steps,
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