import Foundation

final class MatchupService {
    private let networkClient: NetworkClient<VivaErrorResponse>

    init(networkClient: NetworkClient<VivaErrorResponse>) {
        self.networkClient = networkClient
    }

    // MARK: - Matchups

    func getMyMatchups() async throws -> [Matchup] {
        let response: MatchupsResponse = try await networkClient.get(
            path: "/viva/matchups"
        )
        return response.matchups
    }

    func createMatchup(_ matchup: MatchupRequest) async throws -> MatchupDetails {
        return try await networkClient.post(
            path: "/viva/matchups",
            body: matchup
        )
    }

    func getMatchup(matchupId: String) async throws -> MatchupDetails {
        return try await networkClient.get(
            path: "/viva/matchups/\(matchupId)"
        )
    }

    func startMatchup(matchupId: String) async throws -> Matchup {
        return try await networkClient.put(
            path: "/viva/matchups/\(matchupId)/start"
        )
    }

    func cancelMatchup(matchupId: String) async throws -> Matchup {
        return try await networkClient.put(
            path: "/viva/matchups/\(matchupId)/cancel"
        )
    }

    // MARK: - Matchup Users

    func removeMatchupUser(matchupId: String, userId: String) async throws {
        try await networkClient.delete(
            path: "/viva/matchups/\(matchupId)/users/\(userId)"
        )
    }

    // MARK: - Matchup Invites

    func getMatchupInvites(matchupId: String) async throws -> [MatchupInvite] {
        let response: MatchupInvitesResponse = try await networkClient.get(
            path: "/viva/matchups/\(matchupId)/invites"
        )
        return response.invites
    }

    func getMyInvites() async throws -> [MatchupInvite] {
        let response: MatchupInvitesResponse = try await networkClient.get(
            path: "/viva/matchups/invites"
        )
        return response.invites
    }

    func getSentInvites() async throws -> [MatchupInvite] {
        let response: MatchupInvitesResponse = try await networkClient.get(
            path: "/viva/matchups/invites/sent"
        )
        return response.invites
    }

    func createInvite(matchupId: String, side: String, userId: String) async throws -> MatchupInvite {
        return try await networkClient.post(
            path: "/viva/matchups/\(matchupId)/invites",
            queryParams: [
                "side": side,
                "userId": userId
            ]
        )
    }

    func deleteInvite(matchupId: String, inviteCode: String) async throws {
        try await networkClient.delete(
            path: "/viva/matchups/\(matchupId)/invites/\(inviteCode)"
        )
    }

    func acceptInvite(inviteCode: String) async throws {
        try await networkClient.put(
            path: "/viva/matchups/invites/\(inviteCode)/accept"
        )
    }
}
