import HealthKit
import SwiftUI

/// Manages HealthKit data access and processing for the app
final class HealthKitDataManager: ObservableObject {
    private let healthStore = HKHealthStore()
    private let userSession: UserSession
    private let userMeasurementService: UserMeasurementService
    private var queryHandlers: [MeasurementType: HealthDataQuery] = [:]

    @Published var isAuthorized = false

    init(
        userSession: UserSession,
        userMeasurementService: UserMeasurementService
    ) {
        self.userSession = userSession
        self.userMeasurementService = userMeasurementService
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

    /// Updates and uploads health data for a matchup in a single operation
    /// - Parameters:
    ///   - matchupDetail: The matchup detail to update
    ///   - completion: Callback with the result - success with updated data or failure with error
    func updateAndUploadHealthData(
        matchupDetail: MatchupDetails,
        completion: @escaping (Result<MatchupDetails, Error>) -> Void
    ) {
        guard let userId = userSession.userId else {
            return
        }

        // First update the health data
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
