import Foundation

final class AuthService {
    private let networkClient: NetworkClient
    private let apiKey: String = "AIzaSyBt_443_Npn0Rtx-Rk_xBS5CdAt_FqWHh8"

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    private struct AuthRequest: Encodable {
        let email: String
        let password: String
        let returnSecureToken: Bool
    }

    func signIn(_ email: String, _ password: String) async throws -> AuthResponse {
        return try await networkClient.post(
            path: ":signInWithPassword?key=\(apiKey)",
            body: AuthRequest(
                email: email,
                password: password,
                returnSecureToken: true
            )
        )
    }
    
    func signUp(_ email: String, _ password: String) async throws -> AuthResponse {
        return try await networkClient.post(
            path: ":signUp?key=\(apiKey)",
            body: AuthRequest(
                email: email,
                password: password,
                returnSecureToken: true
            )
        )
    }
}
