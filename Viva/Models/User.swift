enum FriendStatus: String, Codable {
    case friend = "FRIEND"
    case requestSent = "REQUEST_SENT"
    case requestReceived = "REQUEST_RECEIVED"
    case notFriend = "NOT_FRIEND"
}

struct User: Encodable, Decodable, Identifiable, Equatable {
    let id: String
    let displayName: String
    let imageUrl: String?
    let friendStatus: FriendStatus?
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id &&
               lhs.displayName == rhs.displayName &&
               lhs.imageUrl == rhs.imageUrl &&
               lhs.friendStatus == rhs.friendStatus
    }
}
