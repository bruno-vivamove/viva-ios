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
        let heartRateType = HKObjectType.categoryType(
            forIdentifier: .highHeartRateEvent)!
        var measurements: [MatchupUserMeasurement] = []
        let queryGroup = DispatchGroup()

        // Query each day separately
        for dayNumber in 0...currentDayNumber {
            queryGroup.enter()
            let (dayStart, dayEnd) = getDayStartEnd(
                startTime: startTime,
                dayNumber: dayNumber
            )

            // Create and execute query for high heart rate events
            let predicate = HKQuery.predicateForSamples(
                withStart: dayStart,
                end: dayEnd,
                options: .strictStartDate
            )
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                defer { queryGroup.leave() }

                if let events = samples as? [HKCategorySample] {
                    // Calculate total minutes of elevated heart rate
                    let totalMinutes = Int(
                        events.reduce(0.0) {
                            $0 + $1.endDate.timeIntervalSince($1.startDate)
                        } / 60.0
                    )
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