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
            AppLogger.info("Attempting to refresh expired token", category: .auth)
            
            guard let refreshToken = userSession.refreshToken else {
                AppLogger.error("No refresh token available, cannot refresh session", category: .auth)
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
                
                AppLogger.info("Token refresh successful", category: .auth)
            } catch {
                AppLogger.error("Token refresh failed: \(error.localizedDescription)", category: .auth)
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
