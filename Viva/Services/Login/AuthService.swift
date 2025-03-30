final class AuthService {
    private let apiKey: String = "AIzaSyBt_443_Npn0Rtx-Rk_xBS5CdAt_FqWHh8"

    private let networkClient: NetworkClient<AuthErrorResponse>
    private let settings: NetworkClientSettings

    init(networkClient: NetworkClient<AuthErrorResponse>) {
        self.networkClient = networkClient
        self.settings = networkClient.settings
    }

    private struct AuthRequest: Encodable {
        let email: String
        let password: String
        let returnSecureToken: Bool
    }

    func signIn(_ email: String, _ password: String) async throws -> AuthResponse {
        return try await networkClient.post(
            path: ":signInWithPassword",
            queryParams: ["key" : apiKey],
            body: AuthRequest(
                email: email,
                password: password,
                returnSecureToken: true
            )
        )
    }
    
    func signUp(_ email: String, _ password: String) async throws -> AuthResponse {
        return try await networkClient.post(
            path: ":signUp",
            queryParams: ["key" : apiKey],
            body: AuthRequest(
                email: email,
                password: password,
                returnSecureToken: true
            )
        )
    }
    
    private struct ResetPasswordRequest: Encodable {
        let email: String
        let requestType = "PASSWORD_RESET"
    }
    
    struct ResetPasswordResponse: Decodable {
        let kind: String
        let email: String
    }
    
    func resetPassword(email: String) async throws -> ResetPasswordResponse {
        return try await networkClient.post(
            path: ":sendOobCode",
            queryParams: ["key" : apiKey],
            body: ResetPasswordRequest(email: email)
        )
    }
}
