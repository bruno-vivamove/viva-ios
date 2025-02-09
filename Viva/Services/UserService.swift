import Foundation

final class UserService {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    func searchUsers(query: String, page: Int = 1, pageSize: Int = 20)
        async throws -> [User]
    {
        // URL encode the query parameter
        guard
            let encodedQuery = query.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed)
        else {
            throw NetworkClientError(
                code: "INVALID_QUERY",
                message: "Invalid search query"
            )
        }

        let response: PaginatedUserResponse = try await networkClient.get(
            path: "/viva/users/search?q=\(encodedQuery)"
        )
        return response.users
    }
}
