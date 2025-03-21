import HealthKit

/// Query implementation for sleep data
class SleepQuery: BaseHealthQuery {
    override func execute(
        userId: String,
        startTime: Date,
        currentDayNumber: Int,
        matchupId: String,
        completion: @escaping ([MatchupUserMeasurement]) -> Void
    ) {
        let sleepType = HKObjectType.categoryType(
            forIdentifier: .sleepAnalysis)!
        var measurements: [MatchupUserMeasurement] = []
        let queryGroup = DispatchGroup()

        // Query each day separately
        for dayNumber in 0...currentDayNumber {
            queryGroup.enter()
            let (dayStart, dayEnd) = getDayStartEnd(
                startTime: startTime,
                dayNumber: dayNumber
            )

            // Create and execute query for sleep samples
            AppLogger.debug("Day Start: \(dayStart)")
            AppLogger.debug("Day End: \(dayEnd)")

            
            let predicate = HKQuery.predicateForSamples(
                withStart: dayStart,
                end: dayEnd,
                options: .strictStartDate
            )
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                defer { queryGroup.leave() }

                if let sleepSamples = samples as? [HKCategorySample] {
                    // Calculate total minutes of sleep
                    let totalMinutes = Int(
                        sleepSamples.reduce(0.0) {
                            $0 + $1.endDate.timeIntervalSince($1.startDate)
                        } / 60.0
                    )
                    let measurement = MatchupUserMeasurement(
                        matchupId: matchupId,
                        dayNumber: dayNumber,
                        measurementType: .asleep,
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
