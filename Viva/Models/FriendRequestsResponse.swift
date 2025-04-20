struct FriendRequestsResponse: Codable {
    let requests: [UserSummary]
    let page: Int
    let pageSize: Int
    let totalRequests: Int
}
