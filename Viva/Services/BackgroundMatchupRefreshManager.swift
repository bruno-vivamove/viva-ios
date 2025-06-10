import Foundation
import BackgroundTasks
import UIKit

class BackgroundMatchupRefreshManager {
    private let matchupService: MatchupService
    private let userSession: UserSession
    
    init(
        matchupService: MatchupService,
        userSession: UserSession
    ) {
        self.matchupService = matchupService
        self.userSession = userSession
    }
    
    /// Performs background matchup refresh for all matchups involving the specified user
    /// This method is called from silent push notifications
    func performBackgroundMatchupRefresh(for userId: String, completion: @escaping (Bool) -> Void) {
        AppLogger.info("Starting background matchup refresh for user: \(userId)", category: .data)
        
        // Ensure we have a valid user session
        guard userSession.isLoggedIn else {
            AppLogger.warning("User not logged in, skipping background matchup refresh", category: .data)
            completion(false)
            return
        }
        
        // Start background task to ensure we have enough time to complete
        var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "MatchupRefresh") {
            // This block is called if the task takes too long
            AppLogger.warning("Background matchup refresh task expired", category: .data)
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            completion(false)
        }
        
        // Get user's active matchups and filter for those involving the specified user
        fetchAndFilterRelevantMatchups(involving: userId) { [weak self] relevantMatchups in
            guard let self = self else {
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                completion(false)
                return
            }
            
            if relevantMatchups.isEmpty {
                AppLogger.info("No relevant matchups found for user: \(userId)", category: .data)
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                completion(true)
                return
            }
            
            AppLogger.info("Found \(relevantMatchups.count) relevant matchups for background refresh", category: .data)
            
            // Refresh all relevant matchups
            self.refreshMatchups(relevantMatchups) { success in
                AppLogger.info("Background matchup refresh completed with success: \(success)", category: .data)
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                completion(success)
            }
        }
    }
    
    /// Fetches current user's active matchups and filters for those involving the specified user
    /// TODO: Move this fetching logic to the backend
    private func fetchAndFilterRelevantMatchups(involving userId: String, completion: @escaping ([Matchup]) -> Void) {
        AppLogger.info("Fetching and filtering matchups involving user: \(userId)", category: .data)
        
        Task {
            do {
                // Get all active matchups for the current user
                let matchupsResponse = try await matchupService.getMyMatchups(
                    filter: .ACTIVE,
                    page: 0,
                    pageSize: 100
                )
                
                AppLogger.info("Fetched \(matchupsResponse.matchups.count) active matchups for filtering", category: .data)
                
                // Filter matchups with the specified user
                let relevantMatchups = matchupsResponse.matchups.filter { matchup in
                    let allParticipants = matchup.teams.flatMap { $0.users }
                    return allParticipants.contains(where: { $0.id == userId })
                }
                
                AppLogger.info("Filtered to \(relevantMatchups.count) relevant matchups involving user: \(userId)", category: .data)
                
                DispatchQueue.main.async {
                    completion(relevantMatchups)
                }
            } catch {
                AppLogger.error("Failed to fetch matchups for filtering: \(error)", category: .data)
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
    
    /// Refreshes the details for relevant matchups and posts UI update notifications
    private func refreshMatchups(_ matchups: [Matchup], completion: @escaping (Bool) -> Void) {
        let group = DispatchGroup()
        var refreshResults: [Bool] = []
        let queue = DispatchQueue(label: "background.matchup.refresh", qos: .userInitiated)
        
        for matchup in matchups {
            group.enter()
            
            refreshSingleMatchup(matchup) { success in
                queue.async {
                    refreshResults.append(success)
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            let overallSuccess = !refreshResults.contains(false)
            AppLogger.info("Completed refreshing \(matchups.count) matchups. Success: \(overallSuccess)", category: .data)
            completion(overallSuccess)
        }
    }
    
    /// Refreshes a single matchup and posts appropriate notifications
    private func refreshSingleMatchup(_ matchup: Matchup, completion: @escaping (Bool) -> Void) {
        AppLogger.info("Refreshing matchup: \(matchup.id)", category: .data)
        
        Task {
            do {
                // Fetch fresh matchup details (this is the only necessary API call)
                let freshMatchupDetails = try await matchupService.getMatchup(matchupId: matchup.id)
                
                AppLogger.info("Successfully refreshed matchup: \(freshMatchupDetails.id)", category: .data)
                
                // Post notification that matchup data was updated
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .matchupUpdated,
                        object: freshMatchupDetails
                    )
                    completion(true)
                }
            } catch {
                AppLogger.error("Failed to refresh matchup \(matchup.id): \(error)", category: .data)
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
}
