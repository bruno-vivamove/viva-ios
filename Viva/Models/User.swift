struct User: Codable, Identifiable, Equatable {
    let id: String
    let authId: String
    let emailAddress: String
    let displayName: String
    let imageId: String?
    let caption: String?
    let rewardPoints: Int
    let lastStreakDay: String?
    let streakDays: Int
    let wins: Int
    let losses: Int
    let createTime: String
    let updateTime: String
}

struct UserSummary: Codable, Identifiable, Equatable {
    let id: String
    let displayName: String
    let caption: String?
    let imageUrl: String?
    let friendStatus: FriendStatus?
}

struct UserProfile: Codable {
    let userSummary: UserSummary
    let userStats: UserStats?
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

struct UserAccountUpdateRequest: Codable {
    let emailAddress: String
    let displayName: String
    let caption: String?
}

struct UserAccountResponse: Codable {
    let user: User
}

enum FriendStatus: String, Codable {
    case friend = "FRIEND"
    case requestSent = "REQUEST_SENT"
    case requestReceived = "REQUEST_RECEIVED"
    case notFriend = "NOT_FRIEND"
}
