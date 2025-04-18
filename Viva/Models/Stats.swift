struct MatchupStats: Codable, Equatable {
    let matchupHash: String?
    let displayName: String
    let numberOfMatchups: Int
    let userTeamWins: Int
    let opponentTeamWins: Int
    let userTeamUsers: [User]
    let opponentTeamUsers: [User]
}

struct UserMatchupStatsResponse: Codable {
    let userStats: UserStats
    let matchupStats: [MatchupStats]
}
