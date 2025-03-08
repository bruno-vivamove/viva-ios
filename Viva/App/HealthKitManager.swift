import HealthKit
import SwiftUI

final class HealthKitDataManager: ObservableObject {
    private let healthStore = HKHealthStore()
    private let userSession: UserSession
    @Published var isAuthorized = false

    init(userSession: UserSession) {
        self.userSession = userSession
    }

    func requestAuthorization() {
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

    func updateMatchupData(
        matchupDetail: MatchupDetails,
        completion: @escaping (MatchupDetails) -> Void
    ) {
        guard let startTime = matchupDetail.startTime else { return }
        guard let currentDayNumber = matchupDetail.currentDayNumber else {
            return
        }

        let queryGroup = DispatchGroup()
        let measurementQueue = DispatchQueue(
            label: "com.app.measurements.\(matchupDetail.id)")
        var newMeasurements: [MatchupUserMeasurement] = []

        for measurement in matchupDetail.measurements {
            switch measurement.measurementType {
            case .steps:
                queryGroup.enter()
                querySteps(
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

        queryGroup.notify(queue: .main) {
            var updatedMatchup = matchupDetail
            updatedMatchup.userMeasurements = self.mergeMeasurements(
                existing: matchupDetail.userMeasurements,
                new: newMeasurements
            )
            completion(updatedMatchup)
        }
    }

    private func mergeMeasurements(
        existing: [MatchupUserMeasurement],
        new: [MatchupUserMeasurement]
    ) -> [MatchupUserMeasurement] {
        var merged = existing

        var existingDict: [String: Int] = [:]
        for (index, measurement) in existing.enumerated() {
            let key =
                "\(measurement.userId)_\(measurement.dayNumber)_\(measurement.measurementType.rawValue)"
            existingDict[key] = index
        }

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

    private func getDayStartEnd(
        startTime: Date,
        dayNumber: Int
    ) -> (start: Date, end: Date) {
        let dayLength = 24 * 60 * 60
        let dayStart = startTime.addingTimeInterval(
            Double(dayNumber * dayLength))
        let dayEnd = dayStart.addingTimeInterval(Double(dayLength))
        return (dayStart, dayEnd)
    }

    private func querySteps(
        startTime: Date,
        currentDayNumber: Int,
        matchupId: String,
        completion: @escaping ([MatchupUserMeasurement]) -> Void
    ) {
        let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        var measurements: [MatchupUserMeasurement] = []
        let queryGroup = DispatchGroup()

        for dayNumber in 0...currentDayNumber {
            queryGroup.enter()
            let (dayStart, dayEnd) = getDayStartEnd(
                startTime: startTime,
                dayNumber: dayNumber
            )

            let predicate = HKQuery.predicateForSamples(
                withStart: dayStart,
                end: dayEnd,
                options: .strictStartDate
            )
            let query = HKStatisticsQuery(
                quantityType: stepsType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { [weak self] _, result, error in
                defer { queryGroup.leave() }

                guard let self = self else { return }

                if let sum = result?.sumQuantity() {
                    let steps = Int(sum.doubleValue(for: HKUnit.count()))
                    let measurement = MatchupUserMeasurement(
                        matchupId: matchupId,
                        dayNumber: dayNumber,
                        measurementType: .steps,
                        userId: userSession.userId,
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

    private func queryEnergyBurned(
        startTime: Date,
        currentDayNumber: Int,
        matchupId: String,
        completion: @escaping ([MatchupUserMeasurement]) -> Void
    ) {
        let energyType = HKQuantityType.quantityType(
            forIdentifier: .activeEnergyBurned)!
        var measurements: [MatchupUserMeasurement] = []
        let queryGroup = DispatchGroup()

        for dayNumber in 0...currentDayNumber {
            queryGroup.enter()
            let (dayStart, dayEnd) = getDayStartEnd(
                startTime: startTime,
                dayNumber: dayNumber
            )

            let predicate = HKQuery.predicateForSamples(
                withStart: dayStart,
                end: dayEnd,
                options: .strictStartDate
            )
            let query = HKStatisticsQuery(
                quantityType: energyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { [weak self] _, result, error in
                defer { queryGroup.leave() }

                guard let self = self else { return }

                if let sum = result?.sumQuantity() {
                    let calories = Int(
                        sum.doubleValue(for: HKUnit.kilocalorie()))
                    let measurement = MatchupUserMeasurement(
                        matchupId: matchupId,
                        dayNumber: dayNumber,
                        measurementType: .energyBurned,
                        userId: userSession.userId,
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

    private func queryWorkout(
        type: MeasurementType,
        startTime: Date,
        currentDayNumber: Int,
        matchupId: String,
        completion: @escaping ([MatchupUserMeasurement]) -> Void
    ) {
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

        for dayNumber in 0...currentDayNumber {
            queryGroup.enter()
            let (dayStart, dayEnd) = getDayStartEnd(
                startTime: startTime,
                dayNumber: dayNumber
            )

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

            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: compoundPredicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { [weak self] _, samples, error in
                defer { queryGroup.leave() }

                guard let self = self else { return }

                if let workouts = samples as? [HKWorkout] {
                    let totalMinutes = Int(
                        workouts.reduce(0.0) { $0 + $1.duration } / 60.0
                    )
                    let measurement = MatchupUserMeasurement(
                        matchupId: matchupId,
                        dayNumber: dayNumber,
                        measurementType: type,
                        userId: userSession.userId,
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

    private func queryElevatedHeartRate(
        startTime: Date,
        currentDayNumber: Int,
        matchupId: String,
        completion: @escaping ([MatchupUserMeasurement]) -> Void
    ) {
        let heartRateType = HKObjectType.categoryType(
            forIdentifier: .highHeartRateEvent)!
        var measurements: [MatchupUserMeasurement] = []
        let queryGroup = DispatchGroup()

        for dayNumber in 0...currentDayNumber {
            queryGroup.enter()
            let (dayStart, dayEnd) = getDayStartEnd(
                startTime: startTime,
                dayNumber: dayNumber
            )

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
            ) { [weak self] _, samples, error in
                defer { queryGroup.leave() }

                guard let self = self else { return }

                if let events = samples as? [HKCategorySample] {
                    let totalMinutes = Int(
                        events.reduce(0.0) {
                            $0 + $1.endDate.timeIntervalSince($1.startDate)
                        } / 60.0
                    )
                    let measurement = MatchupUserMeasurement(
                        matchupId: matchupId,
                        dayNumber: dayNumber,
                        measurementType: .elevatedHeartRate,
                        userId: userSession.userId,
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

    private func querySleep(
        startTime: Date,
        currentDayNumber: Int,
        matchupId: String,
        completion: @escaping ([MatchupUserMeasurement]) -> Void
    ) {
        let sleepType = HKObjectType.categoryType(
            forIdentifier: .sleepAnalysis)!
        var measurements: [MatchupUserMeasurement] = []
        let queryGroup = DispatchGroup()

        for dayNumber in 0...currentDayNumber {
            queryGroup.enter()
            let (dayStart, dayEnd) = getDayStartEnd(
                startTime: startTime,
                dayNumber: dayNumber
            )

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
            ) { [weak self] _, samples, error in
                defer { queryGroup.leave() }

                guard let self = self else { return }

                if let sleepSamples = samples as? [HKCategorySample] {
                    let totalMinutes = Int(
                        sleepSamples.reduce(0.0) {
                            $0 + $1.endDate.timeIntervalSince($1.startDate)
                        } / 60.0
                    )
                    let measurement = MatchupUserMeasurement(
                        matchupId: matchupId,
                        dayNumber: dayNumber,
                        measurementType: .asleep,
                        userId: userSession.userId,
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

    private func queryStanding(
        startTime: Date,
        currentDayNumber: Int,
        matchupId: String,
        completion: @escaping ([MatchupUserMeasurement]) -> Void
    ) {
        let standingType = HKObjectType.quantityType(
            forIdentifier: .appleStandTime)!
        var measurements: [MatchupUserMeasurement] = []
        let queryGroup = DispatchGroup()

        for dayNumber in 0...currentDayNumber {
            queryGroup.enter()
            let (dayStart, dayEnd) = getDayStartEnd(
                startTime: startTime,
                dayNumber: dayNumber
            )

            let predicate = HKQuery.predicateForSamples(
                withStart: dayStart,
                end: dayEnd,
                options: .strictStartDate
            )
            let query = HKStatisticsQuery(
                quantityType: standingType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { [weak self] _, result, error in
                defer { queryGroup.leave() }

                guard let self = self else { return }

                if let sum = result?.sumQuantity() {
                    let minutes = Int(sum.doubleValue(for: HKUnit.minute()))
                    let measurement = MatchupUserMeasurement(
                        matchupId: matchupId,
                        dayNumber: dayNumber,
                        measurementType: .standing,
                        userId: userSession.userId,
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
