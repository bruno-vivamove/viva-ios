import Foundation

final class AuthService {
    private static let apiKey = "AIzaSyBt_443_Npn0Rt x-Rk_xBS5CdAt_FqWHh8"
    private static let baseURL =
        "https://identitytoolkit.googleapis.com/v1"

    private let networkClient: NetworkClient

    init() {
        networkClient = NetworkClient(baseUrl: AuthService.baseURL)
    }

    func signIn(email: String, password: String) async throws -> AuthResponse {
        let authRequest = try buildAuthRequest(email: email, password: password)
        
        do {
            return try await networkClient.fetchData(
                request: authRequest, type: AuthResponse.self, errorType: AuthErrorResponse.self)
        } catch let errorResponse as AuthErrorResponse {
            switch errorResponse.error.message {
            case "INVALID_EMAIL", "INVALID_LOGIN_CREDENTIALS":
                throw ClientError(code:"INVALID_LOGIN_CREDENTIALS", message:"Invalid email or password.")
            default:
                throw ClientError(code:"LOGIN_ERROR", message:"Error logging in. Please try again.")
            }
        }
    }

    private func buildAuthRequest(email: String, password: String) throws
        -> URLRequest
    {
        return try networkClient.buildPostRequest(
            path: "/accounts:signInWithPassword?key=\(AuthService.apiKey)",
            body: [
                "email": email,
                "password": password,
                "returnSecureToken": true,
            ])
    }
}
