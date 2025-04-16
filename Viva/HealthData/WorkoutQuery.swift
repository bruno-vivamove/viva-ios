import HealthKit

/// Query implementation for workout data
class WorkoutQuery: BaseHealthQuery {
    private let workoutType: MeasurementType
    
    init(workoutType: MeasurementType) {
        self.workoutType = workoutType
        super.init()
    }
    
    override func execute(
        userId: String,
        startTime: Date,
        currentDayNumber: Int,
        matchupId: String,
        completion: @escaping ([MatchupUserMeasurement]) -> Void
    ) {
        // Map app measurement type to HealthKit workout type
        let hkWorkoutType: HKWorkoutActivityType
        switch workoutType {
        case .walking: hkWorkoutType = .walking
        case .running: hkWorkoutType = .running
        case .cycling: hkWorkoutType = .cycling
        case .swimming: hkWorkoutType = .swimming
        case .yoga: hkWorkoutType = .yoga
        case .strengthTraining: hkWorkoutType = .traditionalStrengthTraining
        default: 
            completion([])
            return
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
                with: hkWorkoutType
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
                        measurementType: self.workoutType,
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