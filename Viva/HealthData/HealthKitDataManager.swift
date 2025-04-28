import HealthKit
import SwiftUI

/// Manages HealthKit data access and processing for the app
final class HealthKitDataManager: ObservableObject {
    private let healthStore = HKHealthStore()
    private let userSession: UserSession
    private let userMeasurementService: UserMeasurementService
    private let workoutService: WorkoutService
    private var queryHandlers: [MeasurementType: HealthDataQuery] = [:]

    @Published var isAuthorized = false

    init(
        userSession: UserSession,
        userMeasurementService: UserMeasurementService,
        workoutService: WorkoutService
    ) {
        self.userSession = userSession
        self.userMeasurementService = userMeasurementService
        self.workoutService = workoutService
        setupQueryHandlers()
    }

    private func setupQueryHandlers() {
        // Register query handlers for each measurement type
        queryHandlers[.steps] = StepsQuery()
        queryHandlers[.energyBurned] = EnergyBurnedQuery()
        queryHandlers[.walking] = WorkoutQuery(workoutType: .walking)
        queryHandlers[.running] = WorkoutQuery(workoutType: .running)
        queryHandlers[.cycling] = WorkoutQuery(workoutType: .cycling)
        queryHandlers[.swimming] = WorkoutQuery(workoutType: .swimming)
        queryHandlers[.yoga] = WorkoutQuery(workoutType: .yoga)
        queryHandlers[.strengthTraining] = WorkoutQuery(
            workoutType: .strengthTraining
        )
        queryHandlers[.elevatedHeartRate] = ElevatedHeartRateQuery()
        queryHandlers[.asleep] = SleepQuery()
        queryHandlers[.standing] = StandingQuery()
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
            success,
            error in
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
            label: "com.app.measurements.\(matchupDetail.id)"
        )
        var newMeasurements: [MatchupUserMeasurement] = []

        // Process each measurement type in the matchup
        for measurement in matchupDetail.measurements {
            if let queryHandler = queryHandlers[measurement.measurementType] {
                queryGroup.enter()
                queryHandler.execute(
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
    
    /// Queries for workouts during the matchup time period
    /// - Parameters:
    ///   - matchupDetail: Current matchup details
    ///   - completion: Callback with the queried workouts
    private func queryWorkouts(
        matchupDetail: MatchupDetails,
        completion: @escaping ([Workout]) -> Void
    ) {
        guard let startTime = matchupDetail.startTime,
              let userId = userSession.userId,
              let user = matchupDetail.teams.flatMap({ $0.users }).first(where: { $0.id == userId })
        else {
            completion([])
            return
        }
        
        // Determine end time - either matchup end time or current time
        let endTime = matchupDetail.endTime ?? Date()
        
        // Create predicate for time range
        let predicate = HKQuery.predicateForSamples(
            withStart: startTime,
            end: endTime,
            options: .strictStartDate
        )
        
        // Sort by start date, most recent first
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: false
        )
        
        var workouts: [Workout] = []
        
        // Query for all workout types
        let query = HKSampleQuery(
            sampleType: .workoutType(),
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            guard let workoutSamples = samples as? [HKWorkout], !workoutSamples.isEmpty else {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            // Process each workout
            for hkWorkout in workoutSamples {
                // Map HKWorkoutActivityType to WorkoutType
                let workoutType = self.mapHKWorkoutTypeToAppType(hkWorkout.workoutActivityType)
                
                // Create workout measurements
                var measurements: [WorkoutMeasurement] = []
                
                // Get ID for the workout
                let workoutId = hkWorkout.uuid.uuidString
                
                // Add energy burned measurement if available
                if let energyBurnedType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
                   let energyStats = hkWorkout.statistics(for: energyBurnedType),
                   let energySum = energyStats.sumQuantity() {
                    let energyBurned = energySum.doubleValue(for: HKUnit.kilocalorie())
                    let energyMeasurement = WorkoutMeasurement(
                        workoutId: workoutId,
                        measurementType: .energyBurned,
                        value: Int(energyBurned)
                    )
                    measurements.append(energyMeasurement)
                }
                
                // Create workout object
                let workout = Workout(
                    id: workoutId,
                    user: user,
                    workoutStartTime: hkWorkout.startDate,
                    workoutEndTime: hkWorkout.endDate,
                    type: workoutType,
                    displayName: self.getWorkoutDisplayName(workoutType),
                    measurements: measurements
                )
                
                workouts.append(workout)
            }
            
            DispatchQueue.main.async {
                completion(workouts)
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Maps HealthKit workout types to app workout types
    private func mapHKWorkoutTypeToAppType(_ hkType: HKWorkoutActivityType) -> WorkoutType {
        switch hkType {
        case .walking: return .walking
        case .running: return .running
        case .cycling: return .cycling
        case .swimming: return .swimming
        case .yoga: return .yoga
        case .traditionalStrengthTraining: return .strengthTraining
        case .basketball: return .basketball
        case .dance: return .dancing
        case .hiking: return .hiking
        case .soccer: return .football
        case .tennis: return .tennis
        case .tableTennis: return .tableTennis
        case .bowling: return .bowling
        case .fishing: return .fishing
        case .martialArts: return .martialArts
        case .pilates: return .pilates
        case .rowing: return .rowing
        case .volleyball: return .volleyball
        default: return .other
        }
    }
    
    /// Gets a display name for a workout type
    private func getWorkoutDisplayName(_ type: WorkoutType) -> String {
        switch type {
        case .basketball: return "Basketball"
        case .walking: return "Walking"
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .strengthTraining: return "Strength Training"
        case .yoga: return "Yoga"
        case .dancing: return "Dancing"
        case .hiking: return "Hiking"
        case .gymWorkout: return "Gym Workout"
        case .football: return "Football"
        case .martialArts: return "Martial Arts"
        case .pilates: return "Pilates"
        case .rowing: return "Rowing"
        case .tennis: return "Tennis"
        case .tableTennis: return "Table Tennis"
        case .bowling: return "Bowling"
        case .fishing: return "Fishing"
        case .gardening: return "Gardening"
        case .volleyball: return "Volleyball"
        case .other: return "Workout"
        }
    }

    /// Updates and uploads health data for a matchup in a single operation
    /// - Parameters:
    ///   - matchupDetail: The matchup detail to update
    ///   - completion: Callback with the result - success with updated data or failure with error
    func updateAndUploadHealthData(
        matchupDetail: MatchupDetails,
        completion: @escaping (Result<MatchupDetails, Error>) -> Void
    ) {
        // First query and upload workouts
        queryWorkouts(matchupDetail: matchupDetail) { workouts in
            // Skip workout upload if no workouts found
            if !workouts.isEmpty {
                Task {
                    do {
                        // Upload the workouts
                        try await self.workoutService.recordWorkouts(workouts: workouts)
                        
                        // Continue with regular health data update after workouts are uploaded
                        self.updateAndUploadHealthMeasurements(matchupDetail: matchupDetail, completion: completion)
                    } catch {
                        AppLogger.error(
                            "Failed to save workouts: \(error)",
                            category: .data
                        )
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                }
            } else {
                // No workouts to upload, proceed with regular health data update
                self.updateAndUploadHealthMeasurements(matchupDetail: matchupDetail, completion: completion)
            }
        }
    }
    
    /// Updates and uploads health measurements for a matchup
    /// - Parameters:
    ///   - matchupDetail: The matchup detail to update
    ///   - completion: Callback with the result - success with updated data or failure with error
    private func updateAndUploadHealthMeasurements(
        matchupDetail: MatchupDetails,
        completion: @escaping (Result<MatchupDetails, Error>) -> Void
    ) {
        guard let userId = userSession.userId else {
            return
        }

        // Update the health data
        updateMatchupData(matchupDetail: matchupDetail) { updatedMatchup in
            // Filter only the current user's measurements
            let userMeasurements = updatedMatchup.userMeasurements
                .filter { $0.userId == userId }

            // Skip upload if no measurements
            if userMeasurements.isEmpty {
                completion(.success(updatedMatchup))
                return
            }

            // Upload the measurements
            Task {
                do {
                    // Send all measurements in a single call
                    let savedMatchupDetails =
                        try await self.userMeasurementService
                        .saveUserMeasurements(
                            matchupId: matchupDetail.id,
                            measurements: userMeasurements
                        )

                    // Return the saved details
                    DispatchQueue.main.async {
                        completion(.success(savedMatchupDetails))
                    }
                } catch {
                    AppLogger.error(
                        "Failed to save measurements: \(error)",
                        category: .data
                    )
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
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
}
