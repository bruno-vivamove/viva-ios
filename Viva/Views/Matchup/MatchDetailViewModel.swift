import Foundation
import OrderedCollections

@MainActor
class MatchupDetailViewModel: ObservableObject {
    let matchupService: MatchupService
    let friendService: FriendService
    let userService: UserService
    let userSession: UserSession
    let healthKitDataManager: HealthKitDataManager

    private let matchupId: String

    @Published var matchup: MatchupDetails?
    @Published var totalMatchupMeasurementPairs:
        OrderedDictionary<MeasurementType, MatchupMeasurementPair>?
    @Published var matchupMeasurementPairsByDay:
        [OrderedDictionary<MeasurementType, MatchupMeasurementPair>]?

    @Published var isLoading = false
    @Published var error: Error?

    init(
        matchupService: MatchupService,
        friendService: FriendService,
        userService: UserService,
        userSession: UserSession,
        healthKitDataManager: HealthKitDataManager,
        matchupId: String
    ) {
        self.matchupService = matchupService
        self.friendService = friendService
        self.userService = userService
        self.userSession = userSession
        self.matchupId = matchupId
        self.healthKitDataManager = healthKitDataManager

        // Matchup created observer
        NotificationCenter.default.addObserver(
            forName: .matchupInviteSent,
            object: nil,
            queue: .main
        ) { notification in
            if let matchupInvite = notification.object as? MatchupInvite {
                Task { @MainActor in
                    if matchupInvite.matchupId == matchupId {
                        self.matchup?.invites.append(matchupInvite)
                    }
                }
            }
        }

        // Matchup invite deleted observer
        NotificationCenter.default.addObserver(
            forName: .matchupInviteDeleted,
            object: nil,
            queue: .main
        ) { notification in
            if let matchupInvite = notification.object as? MatchupInvite {
                Task { @MainActor in
                    self.matchup?.invites.removeAll(where: {
                        $0.inviteCode == matchupInvite.inviteCode
                    })
                }
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(
            self, name: .matchupInviteSent, object: nil)
    }

    func loadData() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            let matchup: MatchupDetails = try await matchupService.getMatchup(
                matchupId: matchupId)
            self.matchup = matchup
            self.updateMeasuerments(matchup: matchup)

            if matchup.status == .active {
                healthKitDataManager.updateMatchupData(matchupDetail: matchup) {
                    updatedMatchup in
                    Task {
                        // Get only the current user's measurements
                        let userMeasurements = updatedMatchup.userMeasurements
                            .filter {
                                $0.userId == self.userSession.getUserId()
                            }

                        if userMeasurements.isEmpty {
                            return
                        }

                        do {
                            // Send all measurements in a single call
                            let savedMatchupDetails =
                                try await self.matchupService
                                .saveUserMeasurements(
                                    matchupId: self.matchupId,
                                    measurements: userMeasurements
                                )

                            self.updateMeasuerments(matchup: savedMatchupDetails)
                        } catch {
                            print("Failed to save measurements: \(error)")
                        }
                    }
                }
            }
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func updateMeasuerments(matchup: MatchupDetails)
    {
        // Create set of left user IDs first
        let leftUserIds = Set(matchup.leftUsers.map { $0.id })

        // Initialize dictionaries with empty pairs
        let emptyPair = { (type: MeasurementType) in
            MatchupMeasurementPair(
                measurementType: type,
                leftValue: 0, leftPoints: 0,
                rightValue: 0, rightPoints: 0
            )
        }

        let totalMatchupMeasurementPairs = OrderedDictionary(
            uniqueKeysWithValues: matchup.measurements.map {
                ($0.measurementType, emptyPair($0.measurementType))
            }
        )

        // Calculate days elapsed (current day is included, so add 1)
        let numberOfDays = (matchup.currentDayNumber ?? 0) + 1
        let matchupMeasurementPairsByDay = Array(
            repeating: totalMatchupMeasurementPairs, count: numberOfDays)

        // Process measurements
        let (
            updatedPairs, updatedDailyPairs
        ) = matchup.userMeasurements.reduce(
            (totalMatchupMeasurementPairs, matchupMeasurementPairsByDay)
        ) { accumulator, measurement in
            var (pairs, dailyPairs) = accumulator

            if var pair = pairs[measurement.measurementType],
                var dailyPair = dailyPairs[measurement.dayNumber][
                    measurement.measurementType]
            {

                if leftUserIds.contains(measurement.userId) {
                    pair.leftValue += measurement.value
                    pair.leftPoints += measurement.points
                    dailyPair.leftValue += measurement.value
                    dailyPair.leftPoints += measurement.points
                } else {
                    pair.rightValue += measurement.value
                    pair.rightPoints += measurement.points
                    dailyPair.rightValue += measurement.value
                    dailyPair.rightPoints += measurement.points
                }

                pairs[measurement.measurementType] = pair
                dailyPairs[measurement.dayNumber][measurement.measurementType] =
                    dailyPair
            }

            return (pairs, dailyPairs)
        }

        // Update the view model
        self.matchup = matchup
        self.totalMatchupMeasurementPairs = updatedPairs
        self.matchupMeasurementPairsByDay = updatedDailyPairs
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
            let hours = value / 3600
            let minutes = (value % 3600) / 60

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

    // Helper to check if a position is open
    func hasOpenPosition(side: MatchupUser.Side) -> Bool {
        guard let matchup = matchup else { return false }
        let users = side == .left ? matchup.leftUsers : matchup.rightUsers
        return users.count < matchup.usersPerSide
    }
}
