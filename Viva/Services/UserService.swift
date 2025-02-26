import Foundation
import SwiftUI

final class UserService: ObservableObject {
    private let networkClient: NetworkClient<VivaErrorResponse>

    init(networkClient: NetworkClient<VivaErrorResponse>) {
        self.networkClient = networkClient
    }

    func searchUsers(query: String, page: Int = 1, pageSize: Int = 20) async throws -> [User] {
        let response: PaginatedUserResponse = try await networkClient.get(
            path: "/viva/users/search",
            queryParams: [
                "q": query,
                "page": page,
                "page_size": pageSize
            ]
        )
        return response.users
    }
}
