import Foundation

final class AuthService {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    func signIn(email: String, password: String) async throws -> AuthResponse {
        let authRequest = try networkClient.buildPostRequest(
            path: "",
            body: [
                "email": email,
                "password": password,
                "returnSecureToken": true,
            ])
        
        debugRequest(authRequest)

        do {
            return try await networkClient.fetchData(
                request: authRequest,
                type: AuthResponse.self,
                errorType: AuthErrorResponse.self)
        } catch let errorResponse as AuthErrorResponse {
            print("Auth Error: " + errorResponse.error.message)
            switch errorResponse.error.message {
            case "MISSING_EMAIL", "INVALID_EMAIL", "INVALID_LOGIN_CREDENTIALS":
                throw NetworkClientError(
                    code: "INVALID_LOGIN_CREDENTIALS",
                    message: "Invalid email or password.")
            default:
                throw NetworkClientError(
                    code: "LOGIN_ERROR",
                    message: "Error logging in. Please try again.")
            }
        } catch let error as NetworkClientError {
            print("Network Client Error: " + error.message!)
            throw error
        } catch {
            print("Unknown Error: " + error.localizedDescription)
            throw error
        }
    }
    
    func debugRequest(_ request: URLRequest) {
        print("🌐 URL: \(request.url?.absoluteString ?? "nil")")
        print("📍 Method: \(request.httpMethod ?? "nil")")
        print("📋 Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        if let body = request.httpBody {
            if let bodyString = String(data: body, encoding: .utf8) {
                print("📦 Body: \(bodyString)")
            } else {
                print("📦 Body: \(body) (not UTF-8)")
            }
        }
        
        print("⏰ Timeout: \(request.timeoutInterval)")
        print("🔒 Cache Policy: \(request.cachePolicy)")
    }
}
