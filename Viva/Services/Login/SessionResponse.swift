struct SessionResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let userProfile: UserProfile
}

struct RefreshSessionResponse: Codable {
    let accessToken: String
    let refreshToken: String
}
