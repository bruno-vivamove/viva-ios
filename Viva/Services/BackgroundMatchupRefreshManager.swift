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
    
    /// Performs background matchup refresh for specific matchups by ID
    /// This method is called from silent push notifications when targeting specific matchups
    func performBackgroundMatchupRefresh(for matchupIds: [String], completion: @escaping (UIBackgroundFetchResult) -> Void) {
        guard !matchupIds.isEmpty else {
            AppLogger.info("No matchup IDs provided for background refresh", category: .data)
            completion(.noData)
            return
        }
        
        AppLogger.info("Starting background refresh for \(matchupIds.count) specific matchup(s): \(matchupIds)", category: .data)
        
        guard userSession.isLoggedIn else {
            AppLogger.warning("User not logged in, skipping background matchup refresh", category: .data)
            completion(.failed)
            return
        }
        
        refreshMatchups(matchupIds: matchupIds) { success in
            AppLogger.info("Background specific matchup refresh completed with success: \(success)", category: .data)
            completion(success ? .newData : .failed)
        }
    }
    
    // MARK: - Private Helpers
    
    /// Refreshes multiple matchups by ID and posts notifications
    private func refreshMatchups(matchupIds: [String], completion: @escaping (Bool) -> Void) {
        guard !matchupIds.isEmpty else {
            completion(true)
            return
        }
        
        AppLogger.info("Refreshing \(matchupIds.count) matchups", category: .data)
        
        let group = DispatchGroup()
        var refreshResults: [Bool] = []
        let queue = DispatchQueue(label: "background.matchup.refresh", qos: .userInitiated)
        
        for matchupId in matchupIds {
            group.enter()
            
            Task {
                do {
                    let freshMatchupDetails = try await matchupService.getMatchup(matchupId: matchupId)
                    AppLogger.info("Successfully refreshed matchup: \(freshMatchupDetails.id)", category: .data)
                    
                    await MainActor.run {
                        self.postMatchupUpdateNotification(for: freshMatchupDetails)
                    }
                    
                    queue.async {
                        refreshResults.append(true)
                        group.leave()
                    }
                } catch {
                    AppLogger.error("Failed to refresh matchup \(matchupId): \(error)", category: .data)
                    queue.async {
                        refreshResults.append(false)
                        group.leave()
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            let overallSuccess = !refreshResults.contains(false)
            AppLogger.info("Completed refreshing \(matchupIds.count) matchups. Success: \(overallSuccess)", category: .data)
            completion(overallSuccess)
        }
    }
    
    /// Posts notification that matchup data was updated
    private func postMatchupUpdateNotification(for matchupDetails: MatchupDetails) {
        NotificationCenter.default.post(
            name: .matchupUpdated,
            object: matchupDetails
        )
    }
}
