import Foundation

final class SessionService {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    func createSession(_ idToken: String) async throws -> SessionResponse {
        struct CreateSessionRequest: Encodable {
            let idToken: String
        }
        
        return try await networkClient.post(
            path: "/viva/session",
            body: CreateSessionRequest(idToken: idToken)
        )
    }
}
