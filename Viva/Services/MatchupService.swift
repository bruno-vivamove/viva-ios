import Foundation

final class MatchupService: ObservableObject {
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
    
    func getMatchup(matchupId: String) async throws -> MatchupDetails {
        return try await networkClient.get(
            path: "/viva/matchups/\(matchupId)"
        )
    }
    
    func createMatchup(_ matchup: MatchupRequest) async throws -> MatchupDetails {
        let matchupDetails: MatchupDetails = try await networkClient.post(
            path: "/viva/matchups",
            body: matchup
        )
        
        NotificationCenter.default.post(
            name: .matchupCreated,
            object: matchupDetails
        )

        return matchupDetails
    }
    
    func startMatchup(matchupId: String) async throws -> Matchup {
        let matchup: Matchup = try await networkClient.put(
            path: "/viva/matchups/\(matchupId)/start"
        )

        NotificationCenter.default.post(
            name: .matchupStarted,
            object: matchup
        )

        return matchup
    }
    
    func cancelMatchup(matchupId: String) async throws -> Matchup {
        let matchup: Matchup = try await networkClient.put(
            path: "/viva/matchups/\(matchupId)/cancel"
        )
        
        NotificationCenter.default.post(
            name: .matchupCanceled,
            object: matchup
        )

        return matchup
    }
    
    // MARK: - Matchup Users
    
    func removeMatchupUser(matchupId: String, userId: String) async throws {
        try await networkClient.delete(
            path: "/viva/matchups/\(matchupId)/users/\(userId)"
        )

        NotificationCenter.default.post(
            name: .matchupUserRemoved,
            object: matchupId
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
    
    func createInvite(matchupId: String, matchupTeamId: String, userId: String) async throws -> MatchupInvite {
        let matchupInvite: MatchupInvite = try await networkClient.post(
            path: "/viva/matchups/\(matchupId)/invites",
            queryParams: [
                "matchupTeamId": matchupTeamId,
                "userId": userId
            ]
        )
        
        NotificationCenter.default.post(
            name: .matchupInviteSent,
            object: matchupInvite
        )
        
        return matchupInvite
    }
    
    func deleteInvite(_ matchupInvite: MatchupInvite) async throws {
        do {
            try await networkClient.delete(
                path: "/viva/matchups/\(matchupInvite.matchupId)/invites/\(matchupInvite.inviteCode)"
            )
        } catch let error as VivaErrorResponse {
            if(error.code != "MATCHUP_INVITE_NOT_FOUND") {
                throw error
            }
        }
        
        NotificationCenter.default.post(
            name: .matchupInviteDeleted,
            object: matchupInvite
        )
    }
    
    func acceptInvite(_ invite: MatchupInvite) async throws {
        try await networkClient.put(
            path: "/viva/matchups/invites/\(invite.inviteCode)/accept"
        )

        NotificationCenter.default.post(
            name: .matchupInviteAccepted,
            object: invite
        )
    }
}
