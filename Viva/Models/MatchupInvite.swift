import Foundation

struct MatchupInvite: Codable, Equatable {
    let inviteCode: String
    let matchupId: String
    let user: User?  // Optional since it can be null for open invites
    let sender: User
    let side: MatchupUser.Side
    let createTime: Date
}

struct MatchupInvitesResponse: Codable {
    let invites: [MatchupInvite]
}
