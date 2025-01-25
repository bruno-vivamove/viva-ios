import Foundation

final class SessionService {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    func createSession(idToken: String) async throws -> SessionResponse {
        let sessionRequest = try networkClient.buildPostRequest(
            path: "/viva/session",
            body: ["idToken": idToken])
        
        return try await networkClient.fetchData(
            request: sessionRequest, type: SessionResponse.self)
    }
}
