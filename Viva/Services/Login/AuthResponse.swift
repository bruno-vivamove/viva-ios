struct AuthResponse: Codable {
    let kind: String
    let localId: String
    let email: String
    let displayName: String?  // Made optional since it's not present in signup response
    let idToken: String
    let registered: Bool?     // Made optional since it's only present in signin response
    let refreshToken: String
    let expiresIn: String
}
