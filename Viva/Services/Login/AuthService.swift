import Foundation

final class AuthService {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    func signIn(_ email: String, _ password: String) async throws -> AuthResponse {
        let authRequest = try networkClient.buildPostRequest(
            path: "",
            body: [
                "email": email,
                "password": password,
                "returnSecureToken": true,
            ])
        
        return try await networkClient.fetchData(
            request: authRequest,
            type: AuthResponse.self,
            errorType: AuthErrorResponse.self)
    }
}
