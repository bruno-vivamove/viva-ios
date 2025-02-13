struct UserProfile: Encodable, Decodable {
    let id: String
    let emailAddress: String
    let displayName: String
    let imageUrl: String?
    let rewardPoints: Int?;
}

struct UserProfileUpdateRequest: Encodable, Decodable {
    let emailAddress: String
    let displayName: String
}
