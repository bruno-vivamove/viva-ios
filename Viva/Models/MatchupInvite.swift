import Foundation

struct MatchupInvite: Codable, Equatable {
    let inviteCode: String
    let matchupTeamId: String
    let matchupId: String
    let user: UserSummaryDto?  // Optional since it can be null for open invites
    let sender: UserSummaryDto
    let createTime: Date
}

struct MatchupInvitesResponse: Codable {
    let invites: [MatchupInvite]
}
