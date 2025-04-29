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
                    // Filter only for asleep samples - use all asleep-related values
                    let asleepSamples = sleepSamples.filter { sample in
                        // Filter for any sleep state that indicates the user is actually asleep
                        // rather than just in bed
                        if #available(iOS 16.0, *) {
                            return [
                                HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                                HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                                HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                                HKCategoryValueSleepAnalysis.asleepREM.rawValue
                            ].contains(sample.value)
                        } else {
                            // For backward compatibility with older iOS versions
                            return sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue
                        }
                    }
                    
                    // Calculate total minutes of sleep
                    let totalMinutes = Int(
                        asleepSamples.reduce(0.0) {
                            $0 + $1.endDate.timeIntervalSince($1.startDate)
                        } / 60.0
                    )
                    let measurement = MatchupUserMeasurement(
                        matchupId: matchupId,
                        dayNumber: dayNumber,
                        measurementType: .asleep,
                        userId: userId,
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
