import Foundation

final class SessionService {
    private let networkClient: NetworkClient<VivaErrorResponse>

    init(networkClient: NetworkClient<VivaErrorResponse>) {
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
    
    func refreshSession(_ refreshToken: String) async throws -> RefreshSessionResponse {
        struct RefreshSessionRequest: Encodable {
            let refreshToken: String
        }
        
        return try await networkClient.post(
            path: "/viva/session/refresh",
            body: RefreshSessionRequest(refreshToken: refreshToken)
        )
    }
}
