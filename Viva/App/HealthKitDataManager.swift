import HealthKit
import SwiftUI

/// Manages HealthKit data access and processing for the app
final class HealthKitDataManager: ObservableObject {
    private let healthStore = HKHealthStore()
    private let userSession: UserSession
    @Published var isAuthorized = false

    init(userSession: UserSession) {
        self.userSession = userSession
    }

    /// Requests authorization from the user to access HealthKit data
    func requestAuthorization() {
        // Define health data types we want to access
        let typesToRead: Set = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
            HKObjectType.categoryType(forIdentifier: .highHeartRateEvent)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        ]

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) {
            success, error in
            DispatchQueue.main.async {
                self.isAuthorized = success
            }
        }
    }

    /// Updates matchup data with the user's health metrics
    /// - Parameters:
    ///   - matchupDetail: Current matchup details
    ///   - completion: Callback with updated matchup details
    func updateMatchupData(
        matchupDetail: MatchupDetails,
        completion: @escaping (MatchupDetails) -> Void
    ) {
        guard let startTime = matchupDetail.startTime,
            let currentDayNumber = matchupDetail.currentDayNumber,
            let userId = userSession.userId
        else {
            return
        }

        // Use dispatch group to coordinate multiple async health queries
        let queryGroup = DispatchGroup()
        let measurementQueue = DispatchQueue(
            label: "com.app.measurements.\(matchupDetail.id)")
        var newMeasurements: [MatchupUserMeasurement] = []

        // Process each measurement type in the matchup
        for measurement in matchupDetail.measurements {
            switch measurement.measurementType {
            case .steps:
                queryGroup.enter()
                querySteps(
                    userId: userId,
                    startTime: startTime,
                    currentDayNumber: currentDayNumber,
                    matchupId: matchupDetail.id
                ) { measurements in
                    measurementQueue.async {
                        newMeasurements.append(contentsOf: measurements)
                        queryGroup.leave()
                    }
                }
            case .energyBurned:
                queryGroup.enter()
                queryEnergyBurned(
                    userId: userId,
                    startTime: startTime,
                    currentDayNumber: currentDayNumber,
                    matchupId: matchupDetail.id
                ) { measurements in
                    measurementQueue.async {
                        newMeasurements.append(contentsOf: measurements)
                        queryGroup.leave()
                    }
                }
            case .walking, .running, .cycling, .swimming, .yoga,
                .strengthTraining:
                queryGroup.enter()
                queryWorkout(
                    userId: userId,
                    type: measurement.measurementType,
                    startTime: startTime,
                    currentDayNumber: currentDayNumber,
                    matchupId: matchupDetail.id
                ) { measurements in
                    measurementQueue.async {
                        newMeasurements.append(contentsOf: measurements)
                        queryGroup.leave()
                    }
                }
            case .elevatedHeartRate:
                queryGroup.enter()
                queryElevatedHeartRate(
                    userId: userId,
                    startTime: startTime,
                    currentDayNumber: currentDayNumber,
                    matchupId: matchupDetail.id
                ) { measurements in
                    measurementQueue.async {
                        newMeasurements.append(contentsOf: measurements)
                        queryGroup.leave()
                    }
                }
            case .asleep:
                queryGroup.enter()
                querySleep(
                    userId: userId,
                    startTime: startTime,
                    currentDayNumber: currentDayNumber,
                    matchupId: matchupDetail.id
                ) { measurements in
                    measurementQueue.async {
                        newMeasurements.append(contentsOf: measurements)
                        queryGroup.leave()
                    }
                }
            case .standing:
                queryGroup.enter()
                queryStanding(
                    userId: userId,
                    startTime: startTime,
                    currentDayNumber: currentDayNumber,
                    matchupId: matchupDetail.id
                ) { measurements in
                    measurementQueue.async {
                        newMeasurements.append(contentsOf: measurements)
                        queryGroup.leave()
                    }
                }
            }
        }

        // Once all queries complete, update the matchup with new data
        queryGroup.notify(queue: .main) {
            var updatedMatchup = matchupDetail
            updatedMatchup.userMeasurements = self.mergeMeasurements(
                existing: matchupDetail.userMeasurements,
                new: newMeasurements
            )
            completion(updatedMatchup)
        }
    }

    /// Merges new measurements with existing ones, replacing duplicates
    private func mergeMeasurements(
        existing: [MatchupUserMeasurement],
        new: [MatchupUserMeasurement]
    ) -> [MatchupUserMeasurement] {
        var merged = existing

        // Create dictionary for fast lookup of existing measurements
        var existingDict: [String: Int] = [:]
        for (index, measurement) in existing.enumerated() {
            let key =
                "\(measurement.userId)_\(measurement.dayNumber)_\(measurement.measurementType.rawValue)"
            existingDict[key] = index
        }

        // Replace existing or add new measurements
        for newMeasurement in new {
            let key =
                "\(newMeasurement.userId)_\(newMeasurement.dayNumber)_\(newMeasurement.measurementType.rawValue)"
            if let existingIndex = existingDict[key] {
                merged[existingIndex] = newMeasurement
            } else {
                merged.append(newMeasurement)
            }
        }

        return merged
    }

    /// Calculates the start and end dates for a specific day in the matchup
    private func getDayStartEnd(
        startTime: Date,
        dayNumber: Int
    ) -> (start: Date, end: Date) {
        let dayLength = 24 * 60 * 60 // seconds in a day
        let dayStart = startTime.addingTimeInterval(
            Double(dayNumber * dayLength))
        let dayEnd = dayStart.addingTimeInterval(Double(dayLength))
        return (dayStart, dayEnd)
    }

    /// Queries step count data for each day in the matchup
    private func querySteps(
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

    /// Queries calories burned data for each day in the matchup
    private func queryEnergyBurned(
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
                        completeDay: dayNumber < currentDayNumber,
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

    /// Queries workout data of a specific type for each day in the matchup
    private func queryWorkout(
        userId: String,
        type: MeasurementType,
        startTime: Date,
        currentDayNumber: Int,
        matchupId: String,
        completion: @escaping ([MatchupUserMeasurement]) -> Void
    ) {
        // Map app measurement type to HealthKit workout type
        let workoutType: HKWorkoutActivityType
        switch type {
        case .walking: workoutType = .walking
        case .running: workoutType = .running
        case .cycling: workoutType = .cycling
        case .swimming: workoutType = .swimming
        case .yoga: workoutType = .yoga
        case .strengthTraining: workoutType = .traditionalStrengthTraining
        default: return
        }

        var measurements: [MatchupUserMeasurement] = []
        let queryGroup = DispatchGroup()

        // Query each day separately
        for dayNumber in 0...currentDayNumber {
            queryGroup.enter()
            let (dayStart, dayEnd) = getDayStartEnd(
                startTime: startTime,
                dayNumber: dayNumber
            )

            // Create compound predicate to filter by date and workout type
            let predicate = HKQuery.predicateForSamples(
                withStart: dayStart,
                end: dayEnd,
                options: .strictStartDate
            )
            let workoutPredicate = HKQuery.predicateForWorkouts(
                with: workoutType
            )
            let compoundPredicate = NSCompoundPredicate(
                andPredicateWithSubpredicates: [predicate, workoutPredicate]
            )

            // Query for workouts of the specific type
            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: compoundPredicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                defer { queryGroup.leave() }

                if let workouts = samples as? [HKWorkout] {
                    // Convert total workout duration to minutes
                    let totalMinutes = Int(
                        workouts.reduce(0.0) { $0 + $1.duration } / 60.0
                    )
                    let measurement = MatchupUserMeasurement(
                        matchupId: matchupId,
                        dayNumber: dayNumber,
                        measurementType: type,
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

    /// Queries elevated heart rate events for each day in the matchup
    private func queryElevatedHeartRate(
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

    /// Queries sleep data for each day in the matchup
    private func querySleep(
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

    /// Queries stand time data for each day in the matchup
    private func queryStanding(
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
