import Combine
import Foundation
import OrderedCollections
import SwiftUI

// Add the ComparisonRowModel struct
struct ComparisonRowModel: Identifiable {
    let id: String
    let type: MeasurementType
    let leftValue: Int
    let leftPoints: Int
    let rightValue: Int
    let rightPoints: Int

    // Derived values
    let formattedLeftValue: String
    let formattedRightValue: String
    let displayName: String
}

@MainActor
class MatchupDetailViewModel: ObservableObject {
    let matchupService: MatchupService
    let userMeasurementService: UserMeasurementService
    let friendService: FriendService
    let userService: UserService
    let userSession: UserSession
    let healthKitDataManager: HealthKitDataManager

    private var matchupId: String
    private var cancellables = Set<AnyCancellable>()

    @Published var matchup: MatchupDetails?
    @Published var totalMatchupMeasurementPairs:
        OrderedDictionary<MeasurementType, MatchupMeasurementPair>?
    @Published var matchupMeasurementPairsByDay:
        [OrderedDictionary<MeasurementType, MatchupMeasurementPair>]?

    // Add the published arrays of ComparisonRowModel
    @Published var totalComparisonRows: [ComparisonRowModel] = []
    @Published var dailyComparisonRows: [ComparisonRowModel] = []

    @Published var isLoading = false
    @Published var error: Error?
    @Published var isCompletedButNotFinalized = false
    
    // Data tracking properties
    private var dataLoadedTime: Date? = nil
    private var dataRequestedTime: Date?

    // Set error only if it's not a network error
    func setError(_ error: Error) {
        // Only store the error if it's not a NetworkClientError
        if !(error is NetworkClientError) {
            self.error = error
        }
    }

    init(
        matchupId: String,
        matchupService: MatchupService,
        userMeasurementService: UserMeasurementService,
        friendService: FriendService,
        userService: UserService,
        userSession: UserSession,
        healthKitDataManager: HealthKitDataManager
    ) {
        self.matchupId = matchupId
        self.matchupService = matchupService
        self.userMeasurementService = userMeasurementService
        self.friendService = friendService
        self.userService = userService
        self.userSession = userSession
        self.healthKitDataManager = healthKitDataManager

        setupNotificationObservers()
    }

    deinit {
        cancellables.removeAll()
    }

    private func setupNotificationObservers() {
        // Matchup creation flow completed observer
        NotificationCenter.default.publisher(
            for: .matchupCreationFlowCompleted
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] notification in
            guard let matchupDetails = notification.object as? MatchupDetails else {
                return
            }
            
            // Get the source from userInfo if available
            if let userInfo = notification.userInfo,
               let source = userInfo["source"] as? String {
               
                // Navigate if source is 'home'
                if source == "history" {
                    self?.matchupId = matchupDetails.id
                    self?.matchup = matchupDetails
                    self?.updateMeasurements(matchup: matchupDetails)
                }
            }
        }
        .store(in: &cancellables)

        // Matchup invite sent observer
        NotificationCenter.default.publisher(for: .matchupInviteSent)
            .compactMap { $0.object as? MatchupInvite }
            .filter { $0.matchupId == self.matchupId }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] matchupInvite in
                guard let self = self else { return }

                if var updatedMatchup = self.matchup {
                    if !updatedMatchup.invites.contains(where: {
                        $0.inviteCode == matchupInvite.inviteCode
                    }) {
                        updatedMatchup.invites.append(matchupInvite)
                        self.matchup = updatedMatchup
                    }
                }
            }
            .store(in: &cancellables)

        // Matchup invite deleted observer
        NotificationCenter.default.publisher(for: .matchupInviteDeleted)
            .compactMap { $0.object as? MatchupInvite }
            .filter { $0.matchupId == self.matchupId }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] matchupInvite in
                guard let self = self else { return }

                if var updatedMatchup = self.matchup {
                    updatedMatchup.invites.removeAll {
                        $0.inviteCode == matchupInvite.inviteCode
                    }
                    self.matchup = updatedMatchup
                }
            }
            .store(in: &cancellables)

        // Refresh when health data is updated
        NotificationCenter.default.publisher(for: .healthDataUpdated)
            .compactMap { $0.object as? MatchupDetails }
            .filter { $0.id == self.matchupId }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedMatchup in
                AppLogger.info("MatchupDetail received health data update for matchup \(updatedMatchup.id)", category: .ui)
                self?.updateMeasurements(matchup: updatedMatchup)
            }
            .store(in: &cancellables)

        // Refresh when workouts are recorded
        NotificationCenter.default.publisher(for: .workoutsRecorded)
            .compactMap { $0.object as? MatchupDetails }
            .filter { $0.id == self.matchupId }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] matchupWithWorkouts in
                AppLogger.info("MatchupDetail received workouts recorded notification for matchup \(matchupWithWorkouts.id)", category: .ui)
                // Reload the full matchup data to get updated measurements
                Task { [weak self] in
                    await self?.loadData()
                }
            }
            .store(in: &cancellables)
    }

    func loadInitialDataIfNeeded() async {
        // Don't load if we've requested data in the last minute, regardless of result
        if let requestedTime = dataRequestedTime, 
           Date().timeIntervalSince(requestedTime) < 60 {
            return
        }
        
        // Only load data if it hasn't been loaded in the last 10 minutes or if matchup is nil
        if matchup == nil || dataLoadedTime == nil || 
           Date().timeIntervalSince(dataLoadedTime!) > 600 {
            // Mark that we've requested data
            dataRequestedTime = Date()
            await loadData()
        }
    }

    func loadData() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            // First, get the matchup details
            let matchup = try await matchupService.getMatchup(
                matchupId: matchupId
            )
            self.matchup = matchup
            self.dataLoadedTime = Date()
            self.updateMeasurements(matchup: matchup)
            isLoading = false

            // Finalize if matchup is completed
            withAnimation(.easeInOut(duration: 0.5)) {
                self.isCompletedButNotFinalized = matchup.status == .completed && !matchup.finalized
            }
            
            // If the matchup is active, update the health data in background
            let isCurrentUserInMatchup = matchup.teams.flatMap { $0.users }.contains { $0.id == userSession.userId }
            
            if isCurrentUserInMatchup {
                if self.isCompletedButNotFinalized {
                    try await finalizeUserParticipation(matchup: matchup)
                } else if matchup.status == .active {
                    // Trigger health data update - UI will be updated via notifications
                    AppLogger.info("MatchupDetail triggering health data update for matchup \(matchup.id)", category: .ui)
                    healthKitDataManager.updateAndUploadHealthData(matchupDetail: matchup)
                }
            }
        } catch {
            self.setError(error)
            isLoading = false
        }
    }

    private func finalizeUserParticipation(matchup: MatchupDetails) async throws
    {
        // Only call finalize if the current user is participating in the matchup
        guard let currentUserId = userSession.userId else {
            return
        }

        let isUserParticipating = matchup.teams.flatMap { $0.users }.contains {
            $0.id == currentUserId
        }
        if !isUserParticipating {
            return
        }

        let finalizedMatchup = try await matchupService.finalizeMatchupUser(
            matchupId: matchupId,
            userId: currentUserId
        )
        self.matchup = finalizedMatchup
        self.updateMeasurements(matchup: finalizedMatchup)
    }

    func updateMeasurements(matchup: MatchupDetails) {
        // Create set of left user IDs
        let leftUserIds = Set(matchup.leftTeam.users.map { $0.id })

        // Create a map of measurement types
        let measurementTypes = matchup.measurements.map { $0.measurementType }

        // Initialize empty values for all measurement types
        var totalValues:
            [MeasurementType: (
                leftValue: Int, leftPoints: Int, rightValue: Int,
                rightPoints: Int
            )] = [:]
        var dailyValues:
            [[MeasurementType: (
                leftValue: Int, leftPoints: Int, rightValue: Int,
                rightPoints: Int
            )]] = []

        // Calculate days elapsed (current day is included, so add 1)
        let numberOfDays = (matchup.currentDayNumber ?? 0) + 1

        // Initialize empty values for all days and measurement types
        for _ in 0..<numberOfDays {
            var dayValues:
                [MeasurementType: (
                    leftValue: Int, leftPoints: Int, rightValue: Int,
                    rightPoints: Int
                )] = [:]
            for type in measurementTypes {
                dayValues[type] = (0, 0, 0, 0)
            }
            dailyValues.append(dayValues)
        }

        // Initialize total values
        for type in measurementTypes {
            totalValues[type] = (0, 0, 0, 0)
        }

        // Process measurements
        for measurement in matchup.userMeasurements {
            if let dayValues = dailyValues[safe: measurement.dayNumber],
                var dayValue = dayValues[measurement.measurementType],
                var totalValue = totalValues[measurement.measurementType]
            {

                // Update daily values
                if leftUserIds.contains(measurement.userId) {
                    dayValue.leftValue += measurement.value
                    dayValue.leftPoints += measurement.points
                    totalValue.leftValue += measurement.value
                    totalValue.leftPoints += measurement.points
                } else {
                    dayValue.rightValue += measurement.value
                    dayValue.rightPoints += measurement.points
                    totalValue.rightValue += measurement.value
                    totalValue.rightPoints += measurement.points
                }

                // Store updated values
                dailyValues[measurement.dayNumber][
                    measurement.measurementType
                ] = dayValue
                totalValues[measurement.measurementType] = totalValue
            }
        }

        // Convert directly to ComparisonRowModel arrays
        self.totalComparisonRows = measurementTypes.compactMap { type in
            guard let values = totalValues[type] else { return nil }

            return ComparisonRowModel(
                id:
                    "\(type.rawValue)-\(values.leftValue)-\(values.rightValue)-\(values.leftPoints)-\(values.rightPoints)",
                type: type,
                leftValue: values.leftValue,
                leftPoints: values.leftPoints,
                rightValue: values.rightValue,
                rightPoints: values.rightPoints,
                formattedLeftValue: formatValue(values.leftValue, for: type),
                formattedRightValue: formatValue(values.rightValue, for: type),
                displayName: displayName(for: type)
            )
        }

        // Also update the daily rows with the last day if available
        if let lastDayValues = dailyValues.last {
            self.dailyComparisonRows = measurementTypes.compactMap { type in
                guard let values = lastDayValues[type] else { return nil }

                return ComparisonRowModel(
                    id:
                        "\(type.rawValue)-day-\(values.leftValue)-\(values.rightValue)-\(values.leftPoints)-\(values.rightPoints)",
                    type: type,
                    leftValue: values.leftValue,
                    leftPoints: values.leftPoints,
                    rightValue: values.rightValue,
                    rightPoints: values.rightPoints,
                    formattedLeftValue: formatValue(
                        values.leftValue,
                        for: type
                    ),
                    formattedRightValue: formatValue(
                        values.rightValue,
                        for: type
                    ),
                    displayName: displayName(for: type)
                )
            }
        }

        // Update the model
        self.matchup = matchup

        // For backward compatibility, still update the dictionaries
        // Can be removed later when all code is refactored
        let emptyPair = { (type: MeasurementType) in
            MatchupMeasurementPair(
                measurementType: type,
                leftValue: 0,
                leftPoints: 0,
                rightValue: 0,
                rightPoints: 0
            )
        }

        var totalPairs = OrderedDictionary<
            MeasurementType, MatchupMeasurementPair
        >(
            uniqueKeysWithValues: measurementTypes.map {
                ($0, emptyPair($0))
            }
        )

        var dailyPairs = Array(repeating: totalPairs, count: numberOfDays)

        for (type, values) in totalValues {
            var pair = totalPairs[type]!
            pair.leftValue = values.leftValue
            pair.leftPoints = values.leftPoints
            pair.rightValue = values.rightValue
            pair.rightPoints = values.rightPoints
            totalPairs[type] = pair
        }

        for (day, dayValues) in dailyValues.enumerated() {
            for (type, values) in dayValues {
                var pair = dailyPairs[day][type]!
                pair.leftValue = values.leftValue
                pair.leftPoints = values.leftPoints
                pair.rightValue = values.rightValue
                pair.rightPoints = values.rightPoints
                dailyPairs[day][type] = pair
            }
        }

        self.totalMatchupMeasurementPairs = totalPairs
        self.matchupMeasurementPairsByDay = dailyPairs
    }

    // Helper function to get display name for measurement type
    func displayName(for measurementType: MeasurementType) -> String {
        switch measurementType {
        case .steps: return "Steps"
        case .energyBurned: return "Active Cal"
        case .elevatedHeartRate: return "Move Mins"
        case .asleep: return "Sleep"
        case .standing: return "Stand Time"
        case .walking: return "Walking"
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .yoga: return "Yoga"
        case .strengthTraining: return "Strength Train"
        }
    }

    // Helper function to format value based on measurement type
    func formatValue(_ value: Int, for measurementType: MeasurementType)
        -> String
    {
        switch measurementType {
        case .steps, .energyBurned:
            return value.formatted()

        case .walking, .running, .cycling, .swimming,
            .yoga, .strengthTraining, .elevatedHeartRate,
            .asleep, .standing:
            let hours = value / 60
            let minutes = value % 60

            if hours > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(minutes)m"
            }
        }
    }

    // Helper to determine if a measurement type uses time format
    func isTimeBasedMeasurement(_ type: MeasurementType) -> Bool {
        switch type {
        case .steps, .energyBurned:
            return false
        case .walking, .running, .cycling, .swimming,
            .yoga, .strengthTraining, .elevatedHeartRate,
            .asleep, .standing:
            return true
        }
    }

    func deleteInvite(inviteCode: String) async {
        if let matchupInvite = matchup?.invites.first(where: {
            $0.inviteCode == inviteCode
        }) {
            await deleteInvite(matchupInvite)
        }
    }

    func deleteInvite(_ matchupInvite: MatchupInvite) async {
        do {
            // Delete the invite
            try await matchupService.deleteInvite(matchupInvite)

            // Update the local state instead of reloading everything
            if var updatedMatchup = self.matchup {
                // Remove the invite from the list
                updatedMatchup.invites.removeAll {
                    $0.inviteCode == matchupInvite.inviteCode
                }
                self.matchup = updatedMatchup
            }
        } catch {
            self.setError(error)
        }
    }
}

// Add this extension for safe array access
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
