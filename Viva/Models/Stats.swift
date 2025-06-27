// Legacy v1 API models - kept for backwards compatibility if needed
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

// V2 API models
struct UserMatchupSeriesStats: Codable, Equatable {
    let matchupHash: String?
    let displayName: String
    let totalMatchups: Int
    let wins: Int
    let losses: Int
    let ties: Int
    let teammates: [UserSummary]
    let opponents: [UserSummary]
    let latestMatchupEndTime: String?
}

struct UserSeriesStatsListResponse: Codable {
    let overallStats: UserStats
    let seriesStats: [UserMatchupSeriesStats]
}
