import Foundation
import OrderedCollections

@MainActor
class MatchupDetailViewModel: ObservableObject {
    private let matchupService: MatchupService
    private let matchupId: String

    @Published var matchup: MatchupDetails?
    @Published var totalMatchupMeasurementPairs:
        OrderedDictionary<MeasurementType, MatchupMeasurementPair>?
    @Published var matchupMeasurementPairsByDay:
        [OrderedDictionary<MeasurementType, MatchupMeasurementPair>]?
    @Published var totalPointsLeft: Int?
    @Published var totalPointsRight: Int?

    @Published var isLoading = false
    @Published var error: Error?

    init(matchupService: MatchupService, matchupId: String) {
        self.matchupService = matchupService
        self.matchupId = matchupId
    }

    func loadData() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            let matchup: MatchupDetails = try await matchupService.getMatchup(
                matchupId: matchupId)
            self.matchup = matchup

            createMeasurementPairs(matchup)
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func createMeasurementPairs(_ matchup: MatchupDetails) {
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
        var numberOfDays = 1
        
        if let startTime = matchup.startTime {
            let calendar = Calendar.current
            let currentDate = Date()
            let daysElapsed =
                calendar.dateComponents([.day], from: startTime, to: currentDate)
                .day ?? 0 + 1

            // Ensure we don't exceed matchup length and aren't negative
            numberOfDays = min(max(daysElapsed, 0), matchup.lengthInDays)
        }

        let matchupMeasurementPairsByDay = Array(
            repeating: totalMatchupMeasurementPairs, count: numberOfDays)

        // Process measurements
        let (
            totalPointsLeft, totalPointsRight, updatedPairs, updatedDailyPairs
        ) = matchup.userMeasurements.reduce(
            (0, 0, totalMatchupMeasurementPairs, matchupMeasurementPairsByDay)
        ) { accumulator, measurement in
            var (leftPoints, rightPoints, pairs, dailyPairs) = accumulator

            if var pair = pairs[measurement.measurementType],
                var dailyPair = dailyPairs[measurement.dayNumber][
                    measurement.measurementType]
            {

                if leftUserIds.contains(measurement.userId) {
                    leftPoints += measurement.points
                    pair.leftValue += measurement.value
                    pair.leftPoints += measurement.points
                    dailyPair.leftValue += measurement.value
                    dailyPair.leftPoints += measurement.points
                } else {
                    rightPoints += measurement.points
                    pair.rightValue += measurement.value
                    pair.rightPoints += measurement.points
                    dailyPair.rightValue += measurement.value
                    dailyPair.rightPoints += measurement.points
                }

                pairs[measurement.measurementType] = pair
                dailyPairs[measurement.dayNumber][measurement.measurementType] =
                    dailyPair
            }

            return (leftPoints, rightPoints, pairs, dailyPairs)
        }

        // Update the view model
        self.totalPointsLeft = totalPointsLeft
        self.totalPointsRight = totalPointsRight
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
}
