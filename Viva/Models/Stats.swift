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
