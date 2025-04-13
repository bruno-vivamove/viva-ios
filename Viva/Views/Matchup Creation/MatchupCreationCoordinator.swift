import SwiftUI

@MainActor
class MatchupCreationCoordinator: ObservableObject {
    let matchupService: MatchupService
    let friendService: FriendService
    let userSession: UserSession
    let challengedUser: User?  // Optional challenged user
    let source: String  // Source identifier for navigation

    @Published var isCreatingMatchup = false
    @Published var error: Error?

    init(
        matchupService: MatchupService,
        friendService: FriendService,
        userSession: UserSession,
        challengedUser: User? = nil,  // Add optional parameter
        source: String = "default"
    ) {
        self.matchupService = matchupService
        self.friendService = friendService
        self.userSession = userSession
        self.challengedUser = challengedUser
        self.source = source
    }

    func createRematchup(
        rematchMatchupId: String,
        selectedCategories: [MatchupCategory]
    ) async
        -> MatchupDetails?
    {
        isCreatingMatchup = true
        defer { isCreatingMatchup = false }

        let measurementTypes =
            selectedCategories
            .filter { $0.isSelected }
            .compactMap { categoryToMeasurementType($0.id) }

        let rematchRequest = RematchRequest(
            displayName: "Rematch Challenge",
            measurementTypes: measurementTypes
        )

        do {
            return
                try await matchupService
                .rematchMatchup(
                    matchupId: rematchMatchupId,
                    rematchRequest: rematchRequest
                )
        } catch {
            self.error = error
            return nil
        }
    }

    func createMatchup(selectedCategories: [MatchupCategory], usersPerSide: Int)
        async -> MatchupDetails?
    {
        isCreatingMatchup = true
        defer { isCreatingMatchup = false }

        let measurementTypes =
            selectedCategories
            .filter { $0.isSelected }
            .compactMap { categoryToMeasurementType($0.id) }

        let request = MatchupRequest(
            displayName: "New Challenge",
            usersPerSide: usersPerSide,
            measurementTypes: measurementTypes
        )

        do {
            let matchup = try await matchupService.createMatchup(request)

            // If this is a direct challenge, send the invite immediately
            if let challengedUser = challengedUser {
                let _ = try await matchupService.createInvite(
                    matchupId: matchup.id,
                    matchupTeamId: matchup.rightTeam.id,  // Challenge opponent to right team
                    userId: challengedUser.id
                )
            }

            return matchup
        } catch {
            self.error = error
            return nil
        }
    }

    private func categoryToMeasurementType(_ categoryId: String)
        -> MeasurementType
    {
        switch categoryId {
        case "calories":
            return .energyBurned
        case "steps":
            return .steps
        case "ehr":
            return .elevatedHeartRate
        case "strength":
            return .strengthTraining
        case "sleep":
            return .asleep
        default:
            return .steps
        }
    }
}
