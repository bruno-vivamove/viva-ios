import Foundation
import SwiftUI

final class UserProfileService: ObservableObject {
    private let networkClient: NetworkClient<VivaErrorResponse>
    private let userSession: UserSession
    
    init(
        networkClient: NetworkClient<VivaErrorResponse>,
        userSession: UserSession
    ) {
        self.networkClient = networkClient
        self.userSession = userSession
    }
    
    func getCurrentUserProfile() async throws -> UserProfile {
        return try await networkClient.get(path: "/users-profiles/me")
    }

    
    func getUserProfile(userId: String) async throws -> UserProfile {
        return try await networkClient.get(path: "/user-profiles/\(userId)")
    }
}
