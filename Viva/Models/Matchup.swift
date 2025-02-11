import Foundation

struct Matchup: Codable, Identifiable {
    let id: String
    let matchupHash: String?
    let displayName: String
    let ownerId: String
    let createTime: Date
    let status: MatchupStatus
    let startTime: Date?
    let endTime: Date?
    let usersPerSide: Int
    let leftUsers: [User]
    let rightUsers: [User]
    
    enum MatchupStatus: String, Codable {
        case pending = "PENDING"
        case active = "ACTIVE"
        case completed = "COMPLETED"
        case cancelled = "CANCELLED"
    }
}

struct MatchupUser: Codable {
    let userId: String
    let matchupId: String
    let side: Side
    let userOrder: Int
    let createTime: Date?
    let userInfo: User?
    
    enum Side: String, Codable {
        case left = "L"
        case right = "R"
    }
}

// Response wrapper for collections
struct MatchupsResponse: Codable {
    let matchups: [Matchup]
}

// Matchup creation request model
struct MatchupRequest: Codable {
    let displayName: String
    let usersPerSide: Int
}
