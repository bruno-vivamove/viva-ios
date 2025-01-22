import Foundation

final class SessionService {
    private let networkClient: NetworkClient

    init() {
        networkClient = NetworkClient()
    }

    func createSession(idToken: String) async throws -> SessionResponse {
        let sessionRequest = try buildSessionRequest(idToken: idToken)
        return try await networkClient.fetchData(
            request: sessionRequest, type: SessionResponse.self)
    }

    private func buildSessionRequest(idToken: String) throws
        -> URLRequest
    {
        return try networkClient.buildPostRequest(
            path: "/viva/session",
            body: ["idToken": idToken])
    }
}
