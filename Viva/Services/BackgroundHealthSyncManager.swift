import BackgroundTasks
import Foundation
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

    /// Performs background health data sync for all active matchups
    /// This method is called from silent push notifications
    func performBackgroundHealthSync(
        completion: @escaping (Bool) -> Void
    ) {
        // TODO many many optimizations
        AppLogger.info(
            "Starting background health sync for all active matchups",
            category: .data
        )

        // Ensure we have a valid user session
        guard userSession.isLoggedIn else {
            AppLogger.warning(
                "User not logged in, skipping background health sync",
                category: .data
            )
            completion(false)
            return
        }

        // Ensure HealthKit is authorized
        guard healthKitDataManager.isAuthorized else {
            AppLogger.warning(
                "HealthKit not authorized, skipping background health sync",
                category: .data
            )
            completion(false)
            return
        }

        // Start background task to ensure we have enough time to complete
        var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(
            withName: "HealthDataSync"
        ) {
            // This block is called if the task takes too long
            AppLogger.warning(
                "Background health sync task expired",
                category: .data
            )
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            completion(false)
        }

        // Get all active matchups for the current user
        fetchRelevantMatchups { [weak self] matchupDetails in
            guard let self = self else {
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                completion(false)
                return
            }

            if matchupDetails.isEmpty {
                AppLogger.info(
                    "No active matchups found for current user",
                    category: .data
                )
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                completion(true)
                return
            }

            AppLogger.info(
                "Found \(matchupDetails.count) active matchups for background sync",
                category: .data
            )

            // Sync health data for all active matchups
            self.syncHealthDataForMatchups(matchupDetails, notifyUserId: nil)
            { success in
                AppLogger.info(
                    "Background health sync completed with success: \(success)",
                    category: .data
                )
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                completion(success)
            }
        }
    }

    /// Fetches all active matchups for the current user
    private func fetchRelevantMatchups(
        completion: @escaping ([MatchupDetails]) -> Void
    ) {
        AppLogger.info(
            "Fetching all active matchups for current user",
            category: .data
        )

        Task {
            do {
                // TODO use locally stored matchups once thats implemented
                // Get all active matchups for the current user
                let matchupsResponse = try await matchupService.getMyMatchups(
                    filter: .ACTIVE,
                    page: 1,
                    pageSize: 100
                )

                // Convert Matchup objects to MatchupDetails by fetching each one
                var matchupDetails: [MatchupDetails] = []

                for matchup in matchupsResponse.matchups {
                    do {
                        // TODO use locally stored version of matchup
                        let details = try await matchupService.getMatchup(
                            matchupId: matchup.id
                        )
                        matchupDetails.append(details)
                    } catch {
                        AppLogger.error(
                            "Failed to fetch matchup details for \(matchup.id): \(error)",
                            category: .data
                        )
                    }
                }

                AppLogger.info(
                    "Found \(matchupDetails.count) active matchups for current user",
                    category: .data
                )

                DispatchQueue.main.async {
                    completion(matchupDetails)
                }
            } catch {
                AppLogger.error(
                    "Failed to fetch active matchups for current user: \(error)",
                    category: .data
                )
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }

    /// Syncs health data for the provided matchups
    private func syncHealthDataForMatchups(
        _ matchupDetails: [MatchupDetails],
        notifyUserId: String? = nil,
        completion: @escaping (Bool) -> Void
    ) {
        let group = DispatchGroup()
        var syncResults: [Bool] = []
        let queue = DispatchQueue(
            label: "background.health.sync",
            qos: .userInitiated
        )

        for matchupDetail in matchupDetails {
            group.enter()

            // Use HealthKitDataManager's updateMatchupData method for consistency
            healthKitDataManager.updateMatchupData(matchupDetail: matchupDetail)
            { [weak self] updatedMatchup in
                guard let self = self else {
                    syncResults.append(false)
                    group.leave()
                    return
                }

                // Extract new measurements and upload them
                self.uploadMeasurements(
                    for: updatedMatchup,
                    notifyUser: notifyUserId
                ) { success in
                    queue.async {
                        syncResults.append(success)
                        group.leave()
                    }
                }
            }
        }

        group.notify(queue: .main) {
            let overallSuccess = !syncResults.contains(false)
            AppLogger.info(
                "Completed syncing \(matchupDetails.count) matchups. Success: \(overallSuccess)",
                category: .data
            )
            completion(overallSuccess)
        }
    }

    /// Uploads measurements using UserMeasurementService
    private func uploadMeasurements(
        for matchupDetails: MatchupDetails,
        notifyUser notifyUserId: String? = nil,
        completion: @escaping (Bool) -> Void
    ) {
        AppLogger.info(
            "Uploading measurements for matchup: \(matchupDetails.id)",
            category: .data
        )

        // Get the current user's measurements from the updated matchup
        guard let currentUserId = userSession.userId else {
            AppLogger.error(
                "No current user ID available for measurement upload",
                category: .data
            )
            completion(false)
            return
        }

        // Filter measurements to only include those for the current user
        let userMeasurements = matchupDetails.userMeasurements.filter {
            measurement in
            measurement.userId == currentUserId
        }

        if userMeasurements.isEmpty {
            AppLogger.info(
                "No new measurements to upload for matchup: \(matchupDetails.id)",
                category: .data
            )
            completion(true)
            return
        }

        AppLogger.info(
            "Uploading \(userMeasurements.count) measurements for matchup: \(matchupDetails.id)",
            category: .data
        )

        Task {
            do {
                _ = try await userMeasurementService.saveUserMeasurements(
                    matchupId: matchupDetails.id,
                    measurements: userMeasurements,
                    requestType: .notifInitiated,
                    notifyUserId: notifyUserId
                )

                AppLogger.info(
                    "Successfully uploaded measurements for matchup: \(matchupDetails.id)",
                    category: .data
                )

                DispatchQueue.main.async {
                    completion(true)
                }
            } catch {
                AppLogger.error(
                    "Failed to upload measurements for matchup \(matchupDetails.id): \(error)",
                    category: .data
                )
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
}
