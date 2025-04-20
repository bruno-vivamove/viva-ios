import SwiftUI

final class FriendService: ObservableObject {
    private let networkClient: NetworkClient<VivaErrorResponse>

    init(networkClient: NetworkClient<VivaErrorResponse>) {
        self.networkClient = networkClient
    }

    // MARK: - Friend Requests Sent

    func getFriendRequestsSent(page: Int = 1, pageSize: Int = 10) async throws -> [UserSummary] {
        let response: PaginatedUserSummaryResponse = try await networkClient.get(
            path: "/friends/requests/sent",
            queryParams: [
                "page": page,
                "page_size": pageSize
            ]
        )
        return response.users
    }

    func sendFriendRequest(userId: String) async throws {
        try await networkClient.post(
            path: "/friends/requests/sent/\(userId)"
        )
    }

    func cancelFriendRequest(userId: String) async throws {
        try await networkClient.delete(
            path: "/friends/requests/sent/\(userId)"
        )
    }

    // MARK: - Friend Requests Received

    func getFriendRequestsReceived(page: Int = 1, pageSize: Int = 10) async throws -> [UserSummary] {
        let response: PaginatedUserSummaryResponse = try await networkClient.get(
            path: "/friends/requests/received",
            queryParams: [
                "page": page,
                "page_size": pageSize
            ]
        )
        return response.users
    }

    func acceptFriendRequest(userId: String) async throws {
        try await networkClient.put(
            path: "/friends/requests/received/\(userId)"
        )
    }

    func declineFriendRequest(userId: String) async throws {
        try await networkClient.delete(
            path: "/friends/requests/received/\(userId)"
        )
    }

    // MARK: - Friends

    func getFriends(page: Int = 1, pageSize: Int = 10) async throws -> [UserSummary] {
        let response: PaginatedUserSummaryResponse = try await networkClient.get(
            path: "/friends",
            queryParams: [
                "page": page,
                "page_size": pageSize
            ]
        )
        return response.users
    }

    func deleteFriend(userId: String) async throws {
        try await networkClient.delete(
            path: "/friends/\(userId)"
        )
    }
}
