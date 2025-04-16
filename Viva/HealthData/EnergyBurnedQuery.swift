import HealthKit

/// Query implementation for energy burned data
class EnergyBurnedQuery: BaseHealthQuery {
    override func execute(
        userId: String,
        startTime: Date,
        currentDayNumber: Int,
        matchupId: String,
        completion: @escaping ([MatchupUserMeasurement]) -> Void
    ) {
        let energyType = HKQuantityType.quantityType(
            forIdentifier: .activeEnergyBurned)!
        var measurements: [MatchupUserMeasurement] = []
        let queryGroup = DispatchGroup()

        // Query each day separately
        for dayNumber in 0...currentDayNumber {
            queryGroup.enter()
            let (dayStart, dayEnd) = getDayStartEnd(
                startTime: startTime,
                dayNumber: dayNumber
            )

            // Create and execute query for daily calories burned
            let predicate = HKQuery.predicateForSamples(
                withStart: dayStart,
                end: dayEnd,
                options: .strictStartDate
            )
            let query = HKStatisticsQuery(
                quantityType: energyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                defer { queryGroup.leave() }

                if let sum = result?.sumQuantity() {
                    let calories = Int(
                        sum.doubleValue(for: HKUnit.kilocalorie()))
                    let measurement = MatchupUserMeasurement(
                        matchupId: matchupId,
                        dayNumber: dayNumber,
                        measurementType: .energyBurned,
                        userId: userId,
                        value: calories,
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