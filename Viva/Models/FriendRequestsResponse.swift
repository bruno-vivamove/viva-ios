struct FriendRequestsResponse: Codable {
    let requests: [User]
    let page: Int
    let pageSize: Int
    let totalRequests: Int
}
