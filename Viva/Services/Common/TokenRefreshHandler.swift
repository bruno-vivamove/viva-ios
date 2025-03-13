import Alamofire
import Foundation

// MARK: - TokenRefreshHandler

actor TokenRefreshHandler {
    private let sessionService: SessionService
    private let userSession: UserSession
    private var refreshTask: Task<Void, Error>?
    
    init(sessionService: SessionService, userSession: UserSession) {
        self.sessionService = sessionService
        self.userSession = userSession
    }
    
    func handleUnauthorizedError() async throws {
        // If we're already refreshing, wait for the existing task to complete
        if let existingTask = refreshTask {
            do {
                try await existingTask.value
                return // Token was refreshed successfully by the other task
            } catch {
                // The other refresh task failed, we'll try again
                refreshTask = nil
            }
        }
        
        // Create a new refresh task
        let task = Task {
            NetworkLogger.log(message: "Attempting to refresh expired token", level: .info)
            
            guard let refreshToken = userSession.refreshToken else {
                NetworkLogger.log(message: "No refresh token available, cannot refresh session", level: .error)
                await userSession.setLoggedOut()
                throw NetworkClientError(code: "NO_REFRESH_TOKEN", message: "No refresh token available")
            }
            
            do {
                // Attempt to refresh the token
                let response = try await sessionService.refreshSession(refreshToken)
                
                // Update the tokens in the user session
                userSession.updateTokens(
                    accessToken: response.accessToken,
                    refreshToken: response.refreshToken
                )
                
                NetworkLogger.log(message: "Token refresh successful", level: .info)
            } catch {
                NetworkLogger.log(message: "Token refresh failed: \(error.localizedDescription)", level: .error)
                Task { @MainActor in
                    await userSession.setLoggedOut()
                }
                throw error
            }
        }
        
        // Store the task and await its result
        refreshTask = task
        
        do {
            try await task.value
            refreshTask = nil
        } catch {
            refreshTask = nil
            throw error
        }
    }
}
