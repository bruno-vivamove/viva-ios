enum FriendStatus: String, Codable {
    case friend = "FRIEND"
    case requestSent = "REQUEST_SENT"
    case requestReceived = "REQUEST_RECEIVED"
    case notFriend = "NOT_FRIEND"
}

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

struct UserAccountResponse: Codable {
    let user: User
}
