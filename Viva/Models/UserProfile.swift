struct UserProfile: Codable {
    let userSummary: UserSummaryDto
    let userStats: UserStats?
}

struct UserProfileUpdateRequest: Codable {
    let emailAddress: String
    let displayName: String
    let caption: String?
}

struct UserStats: Codable {
    let userId: String
    let displayName: String
    let totalMatchups: Int
    let wins: Int
    let losses: Int
    let ties: Int
    let totalElevatedHeartRate: Int
    let totalEnergyBurned: Int
}
