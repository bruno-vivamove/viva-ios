import Foundation

final class UserProfileService {
    private let networkClient: NetworkClient
    private let userSession: UserSession

    init(networkClient: NetworkClient, userSession: UserSession) {
        self.networkClient = networkClient
        self.userSession = userSession
    }

    func getCurrentUserProfile() async throws -> UserProfile {
        let sessionRequest = try networkClient.buildGetRequest(path: "/viva/me")

        return try await networkClient.fetchData(
            request: sessionRequest, type: UserProfile.self)
    }

    func saveCurrentUserProfile(userProfile: UserProfile) async throws
        -> UserProfile
    {
        let sessionRequest = try networkClient.buildPutRequest(
            path: "/viva/me", body: userProfile)

        return try await networkClient.fetchData(
            request: sessionRequest, type: UserProfile.self)
    }
}
