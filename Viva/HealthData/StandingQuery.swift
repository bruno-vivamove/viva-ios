import HealthKit

/// Query implementation for stand time data
class StandingQuery: BaseHealthQuery {
    override func execute(
        userId: String,
        startTime: Date,
        currentDayNumber: Int,
        matchupId: String,
        completion: @escaping ([MatchupUserMeasurement]) -> Void
    ) {
        let standingType = HKObjectType.quantityType(
            forIdentifier: .appleStandTime)!
        var measurements: [MatchupUserMeasurement] = []
        let queryGroup = DispatchGroup()

        // Query each day separately
        for dayNumber in 0...currentDayNumber {
            queryGroup.enter()
            let (dayStart, dayEnd) = getDayStartEnd(
                startTime: startTime,
                dayNumber: dayNumber
            )

            // Create and execute query for stand time
            let predicate = HKQuery.predicateForSamples(
                withStart: dayStart,
                end: dayEnd,
                options: .strictStartDate
            )
            let query = HKStatisticsQuery(
                quantityType: standingType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                defer { queryGroup.leave() }

                if let sum = result?.sumQuantity() {
                    let minutes = Int(sum.doubleValue(for: HKUnit.minute()))
                    let measurement = MatchupUserMeasurement(
                        matchupId: matchupId,
                        dayNumber: dayNumber,
                        measurementType: .standing,
                        userId: userId,
                        completeDay: dayNumber < currentDayNumber,
                        value: minutes,
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