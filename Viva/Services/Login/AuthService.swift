import Foundation

final class AuthService {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    func signIn(_ email: String, _ password: String) async throws -> AuthResponse {
        struct SignInRequest: Encodable {
            let email: String
            let password: String
            let returnSecureToken: Bool
        }
        
        return try await networkClient.post(
            path: "",
            body: SignInRequest(
                email: email,
                password: password,
                returnSecureToken: true
            )
        )
    }
}
