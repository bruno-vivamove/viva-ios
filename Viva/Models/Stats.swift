struct MatchupStats: Codable, Equatable {
    let matchupHash: String?
    let displayName: String
    let numberOfMatchups: Int
    let userTeamWins: Int
    let opponentTeamWins: Int
    let userTeamUsers: [UserSummary]
    let opponentTeamUsers: [UserSummary]
}

struct UserMatchupStatsResponse: Codable {
    let userStats: UserStats
    let matchupStats: [MatchupStats]
}
