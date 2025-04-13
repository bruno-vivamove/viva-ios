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

    private let matchupId: String
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
    }

    func loadData() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            let matchup: MatchupDetails = try await matchupService.getMatchup(
                matchupId: matchupId
            )
            self.matchup = matchup
            self.updateMeasuerments(matchup: matchup)

            // Finalize if matchup is completed
            withAnimation(.easeInOut(duration: 0.5)) {
                self.isCompletedButNotFinalized = matchup.status == .completed && !matchup.finalized
            }
            
            if self.isCompletedButNotFinalized {
                try await finalizeUserParticipation(matchup: matchup)
            } else if matchup.status == .active {
                healthKitDataManager.updateMatchupData(matchupDetail: matchup) {
                    updatedMatchup in
                    Task {
                        // Get only the current user's measurements
                        let userMeasurements = updatedMatchup.userMeasurements
                            .filter {
                                $0.userId == self.userSession.userId
                            }

                        if userMeasurements.isEmpty {
                            return
                        }

                        do {
                            // Send all measurements in a single call
                            let savedMatchupDetails =
                                try await self.userMeasurementService
                                .saveUserMeasurements(
                                    matchupId: self.matchupId,
                                    measurements: userMeasurements
                                )

                            self.updateMeasuerments(
                                matchup: savedMatchupDetails
                            )
                        } catch {
                            AppLogger.error(
                                "Failed to save measurements: \(error)",
                                category: .data
                            )
                        }
                    }
                }
            }
        } catch {
            self.error = error
        }

        isLoading = false
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
        self.updateMeasuerments(matchup: finalizedMatchup)
    }

    func updateMeasuerments(matchup: MatchupDetails) {
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
        case .elevatedHeartRate: return "eHR Mins"
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
            self.error = error
        }
    }
}

// Add this extension for safe array access
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
