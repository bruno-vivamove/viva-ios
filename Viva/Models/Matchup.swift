import Foundation

struct Matchup {
    let id: String
    let leftUsers: [MatchupUser]
    let rightUsers: [MatchupUser]
    let endDate: Date
}

struct MatchupUser {
    let user: User
    let score: Int
}
