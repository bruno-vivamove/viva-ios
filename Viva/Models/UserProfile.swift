struct UserProfile: Encodable, Decodable {
    let id: String
    let emailAddress: String
    let displayName: String
    let imageUrl: String?
    let caption: String?
    let rewardPoints: Int
    let userStats: UserStats?
}

struct UserProfileUpdateRequest: Encodable, Decodable {
    let emailAddress: String
    let displayName: String
    let caption: String?
}

struct UserStats: Encodable, Decodable {
    let userId: String
    let displayName: String
    let totalMatchups: Int
    let wins: Int
    let losses: Int
    let ties: Int
    let totalElevatedHeartRate: Int
    let totalEnergyBurned: Int
}
