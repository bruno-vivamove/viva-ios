import Foundation

struct MatchupInvite: Codable {
    let inviteCode: String
    let matchupId: String
    let user: User?  // Optional since it can be null for open invites
    let side: MatchupUser.Side
    let createTime: Date
}

struct MatchupInvitesResponse: Codable {
    let invites: [MatchupInvite]
}
