import Foundation
import BackgroundTasks
import HealthKit
import UIKit

class BackgroundHealthSyncManager {
    private let matchupService: MatchupService
    private let healthKitDataManager: HealthKitDataManager
    private let userMeasurementService: UserMeasurementService
    private let userSession: UserSession
    
    init(
        matchupService: MatchupService,
        healthKitDataManager: HealthKitDataManager,
        userMeasurementService: UserMeasurementService,
        userSession: UserSession
    ) {
        self.matchupService = matchupService
        self.healthKitDataManager = healthKitDataManager
        self.userMeasurementService = userMeasurementService
        self.userSession = userSession
    }
    
    /// Performs background health data sync for all matchups involving the specified user
    /// This method is called from silent push notifications
    func performBackgroundHealthSync(for userId: String, completion: @escaping (Bool) -> Void) {
        AppLogger.info("Starting background health sync for user: \(userId)", category: .data)
        
        // Ensure we have a valid user session
        guard userSession.isLoggedIn else {
            AppLogger.warning("User not logged in, skipping background health sync", category: .data)
            completion(false)
            return
        }
        
        // Ensure HealthKit is authorized
        guard healthKitDataManager.isAuthorized else {
            AppLogger.warning("HealthKit not authorized, skipping background health sync", category: .data)
            completion(false)
            return
        }
        
        // Start background task to ensure we have enough time to complete
        var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "HealthDataSync") {
            // This block is called if the task takes too long
            AppLogger.warning("Background health sync task expired", category: .data)
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            completion(false)
        }
        
        // Get user's active matchups involving the specified user
        fetchRelevantMatchups(involving: userId) { [weak self] matchupDetails in
            guard let self = self else {
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                completion(false)
                return
            }
            
            if matchupDetails.isEmpty {
                AppLogger.info("No active matchups found for user: \(userId)", category: .data)
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                completion(true)
                return
            }
            
            AppLogger.info("Found \(matchupDetails.count) active matchups for background sync", category: .data)
            
            // Sync health data for all relevant matchups
            self.syncHealthDataForMatchups(matchupDetails) { success in
                AppLogger.info("Background health sync completed with success: \(success)", category: .data)
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                completion(success)
            }
        }
    }
    
    /// Fetches active matchups that involve the specified user
    private func fetchRelevantMatchups(involving userId: String, completion: @escaping ([MatchupDetails]) -> Void) {
        AppLogger.info("Fetching active matchups involving user: \(userId)", category: .data)
        
        Task {
            do {
                // Get active matchups for the specified user
                let matchupsResponse = try await matchupService.getUserMatchups(
                    userId: userId,
                    filter: .ACTIVE,
                    page: 0,
                    pageSize: 100
                )
                
                // Convert Matchup objects to MatchupDetails by fetching each one
                var matchupDetails: [MatchupDetails] = []
                
                for matchup in matchupsResponse.matchups {
                    do {
                        let details = try await matchupService.getMatchup(matchupId: matchup.id)
                        matchupDetails.append(details)
                    } catch {
                        AppLogger.error("Failed to fetch matchup details for \(matchup.id): \(error)", category: .data)
                    }
                }
                
                AppLogger.info("Found \(matchupDetails.count) active matchups for user: \(userId)", category: .data)
                
                DispatchQueue.main.async {
                    completion(matchupDetails)
                }
            } catch {
                AppLogger.error("Failed to fetch matchups for user \(userId): \(error)", category: .data)
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
    
    /// Syncs health data for the provided matchups
    private func syncHealthDataForMatchups(_ matchupDetails: [MatchupDetails], completion: @escaping (Bool) -> Void) {
        let group = DispatchGroup()
        var syncResults: [Bool] = []
        let queue = DispatchQueue(label: "background.health.sync", qos: .userInitiated)
        
        for matchupDetail in matchupDetails {
            group.enter()
            
            // Use HealthKitDataManager's updateMatchupData method for consistency
            healthKitDataManager.updateMatchupData(matchupDetail: matchupDetail) { [weak self] updatedMatchup in
                guard let self = self else {
                    syncResults.append(false)
                    group.leave()
                    return
                }
                
                // Extract new measurements and upload them
                self.uploadMeasurements(for: updatedMatchup) { success in
                    queue.async {
                        syncResults.append(success)
                        group.leave()
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            let overallSuccess = !syncResults.contains(false)
            AppLogger.info("Completed syncing \(matchupDetails.count) matchups. Success: \(overallSuccess)", category: .data)
            completion(overallSuccess)
        }
    }
    
    /// Uploads measurements using UserMeasurementService
    private func uploadMeasurements(for matchupDetails: MatchupDetails, completion: @escaping (Bool) -> Void) {
        AppLogger.info("Uploading measurements for matchup: \(matchupDetails.id)", category: .data)
        
        // Get the current user's measurements from the updated matchup
        guard let currentUserId = userSession.userId else {
            AppLogger.error("No current user ID available for measurement upload", category: .data)
            completion(false)
            return
        }
        
        // Filter measurements to only include those for the current user
        let userMeasurements = matchupDetails.userMeasurements.filter { measurement in
            measurement.userId == currentUserId
        }
        
        if userMeasurements.isEmpty {
            AppLogger.info("No new measurements to upload for matchup: \(matchupDetails.id)", category: .data)
            completion(true)
            return
        }
        
        AppLogger.info("Uploading \(userMeasurements.count) measurements for matchup: \(matchupDetails.id)", category: .data)
        
        Task {
            do {
                _ = try await userMeasurementService.saveUserMeasurements(
                    matchupId: matchupDetails.id,
                    measurements: userMeasurements,
                    isBackgroundUpdate: true
                )
                
                AppLogger.info("Successfully uploaded measurements for matchup: \(matchupDetails.id)", category: .data)
                
                DispatchQueue.main.async {
                    completion(true)
                }
            } catch {
                AppLogger.error("Failed to upload measurements for matchup \(matchupDetails.id): \(error)", category: .data)
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
}