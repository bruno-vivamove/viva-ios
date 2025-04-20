struct FriendRequestsResponse: Codable {
    let requests: [UserSummaryDto]
    let page: Int
    let pageSize: Int
    let totalRequests: Int
}
