enum FriendStatus: String, Codable {
    case friend = "FRIEND"
    case requestSent = "REQUEST_SENT"
    case requestReceived = "REQUEST_RECEIVED"
    case notFriend = "NOT_FRIEND"
}

struct User: Encodable, Decodable, Identifiable {
    let id: String
    let displayName: String
    let imageUrl: String?
    let friendStatus: FriendStatus?
}
