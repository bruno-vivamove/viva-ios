struct UserProfile: Encodable, Decodable {
    let id: String
    let emailAddress: String
    let displayName: String
    let imageUrl: String?
    let caption: String?
    let rewardPoints: Int;
    let streakDays: Int;
    let wins: Int;
    let losses: Int;
}

struct UserProfileUpdateRequest: Encodable, Decodable {
    let emailAddress: String
    let displayName: String
    let caption: String?
}
