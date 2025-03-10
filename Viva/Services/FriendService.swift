import SwiftUI

final class FriendService: ObservableObject {
    private let networkClient: NetworkClient<VivaErrorResponse>

    init(networkClient: NetworkClient<VivaErrorResponse>) {
        self.networkClient = networkClient
    }

    // MARK: - Friend Requests Sent

    func getFriendRequestsSent(page: Int = 1, pageSize: Int = 10) async throws -> [User] {
        let response: PaginatedUserResponse = try await networkClient.get(
            path: "/viva/friends/requests/sent",
            queryParams: [
                "page": page,
                "page_size": pageSize
            ]
        )
        return response.users
    }

    func sendFriendRequest(userId: String) async throws {
        try await networkClient.post(
            path: "/viva/friends/requests/sent/\(userId)"
        )
    }

    func cancelFriendRequest(userId: String) async throws {
        try await networkClient.delete(
            path: "/viva/friends/requests/sent/\(userId)"
        )
    }

    // MARK: - Friend Requests Received

    func getFriendRequestsReceived(page: Int = 1, pageSize: Int = 10) async throws -> [User] {
        let response: PaginatedUserResponse = try await networkClient.get(
            path: "/viva/friends/requests/received",
            queryParams: [
                "page": page,
                "page_size": pageSize
            ]
        )
        return response.users
    }

    func acceptFriendRequest(userId: String) async throws {
        try await networkClient.put(
            path: "/viva/friends/requests/received/\(userId)"
        )
    }

    func declineFriendRequest(userId: String) async throws {
        try await networkClient.delete(
            path: "/viva/friends/requests/received/\(userId)"
        )
    }

    // MARK: - Friends

    func getFriends(page: Int = 1, pageSize: Int = 10) async throws -> [User] {
        let response: PaginatedUserResponse = try await networkClient.get(
            path: "/viva/friends",
            queryParams: [
                "page": page,
                "page_size": pageSize
            ]
        )
        return response.users
    }

    func deleteFriend(userId: String) async throws {
        try await networkClient.delete(
            path: "/viva/friends/\(userId)"
        )
    }
}
