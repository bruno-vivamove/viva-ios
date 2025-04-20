struct MatchupStats: Codable, Equatable {
    let matchupHash: String?
    let displayName: String
    let numberOfMatchups: Int
    let userTeamWins: Int
    let opponentTeamWins: Int
    let userTeamUsers: [UserSummaryDto]
    let opponentTeamUsers: [UserSummaryDto]
}

struct UserMatchupStatsResponse: Codable {
    let userStats: UserStats
    let matchupStats: [MatchupStats]
}
