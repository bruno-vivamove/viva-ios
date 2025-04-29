import Combine
import Foundation

class MatchupCardViewModel: ObservableObject, Identifiable {
    @Published var matchupDetails: MatchupDetails?
    @Published var isLoading: Bool
    @Published var error: Error?

    private let matchupId: String
    private let matchupService: MatchupService
    private let userMeasurementService: UserMeasurementService
    private let healthKitDataManager: HealthKitDataManager
    private let userSession: UserSession
    private var cancellables = Set<AnyCancellable>()

    // Data tracking properties
    private var dataLoadedTime: Date?
    private var dataRequestedTime: Date?
    private var lastRefreshTime: Date?

    init(
        matchupId: String,
        matchupService: MatchupService,
        userMeasurementService: UserMeasurementService,
        healthKitDataManager: HealthKitDataManager,
        userSession: UserSession,
        lastRefreshTime: Date? = nil
    ) {
        self.matchupId = matchupId
        self.matchupService = matchupService
        self.userMeasurementService = userMeasurementService
        self.healthKitDataManager = healthKitDataManager
        self.userSession = userSession
        self.lastRefreshTime = lastRefreshTime
        self.isLoading = true

        // The UserMeasurementService is now injected in VivaAppObjects
        // healthKitDataManager.setupUserMeasurementService(userMeasurementService)
        
        // Listen for relevant notifications that should trigger a refresh
        setupNotificationObservers()
    }

    // Add this method to update the refresh time
    func updateLastRefreshTime(_ newTime: Date?) {
        // Only refresh if the new time is different (and later) than the current one
        if let newTime = newTime,
            lastRefreshTime == nil || newTime > lastRefreshTime!
        {
            lastRefreshTime = newTime
            Task {
                await loadInitialDataIfNeeded()
            }
        }
    }

    @MainActor
    func loadInitialDataIfNeeded() async {
        // Don't load if we've requested data in the last minute, regardless of result
        if let requestedTime = dataRequestedTime, 
           Date().timeIntervalSince(requestedTime) < 60 {
            return
        }
        
        // Only load data if it hasn't been loaded in the last 10 minutes or if matchupDetails is nil
        if matchupDetails == nil || dataLoadedTime == nil || 
           Date().timeIntervalSince(dataLoadedTime!) > 600 {
            // Mark that we've requested data
            dataRequestedTime = Date()
            await loadData()
        }
    }

    @MainActor
    func loadData(uploadHealthData: Bool = true) async {
        isLoading = true
        error = nil

        do {
            // First, get the basic matchup details
            let details = try await matchupService.getMatchup(
                matchupId: matchupId)

            // If the matchup is active to update the health data
            if details.status == .active && uploadHealthData {
                // Use the unified method for updating and uploading health data
                healthKitDataManager.updateAndUploadHealthData(matchupDetail: details) { [weak self] result in
                    guard let self = self else { return }
                    
                    Task { @MainActor in
                        switch result {
                        case .success(let updatedMatchup):
                            self.matchupDetails = updatedMatchup
                        case .failure(let error):
                            AppLogger.error("Failed to update and upload health data: \(error)", category: .data)
                            self.error = error
                        }
                        self.isLoading = false
                    }
                }
            } else {
                self.matchupDetails = details
                self.isLoading = false
            }
            
            // Update the time when data was successfully loaded
            self.dataLoadedTime = Date()
        } catch {
            AppLogger.error("Error loading matchup details: \(error)", category: .network)
            self.error = error
            self.isLoading = false
        }
    }

    // Handle removing the current user from the matchup
    @MainActor
    func removeCurrentUser(userId: String) async -> Bool {
        do {
            _ = try await matchupService.removeMatchupUser(
                matchupId: matchupId,
                userId: userId)
            return true
        } catch {
            self.error = error
            return false
        }
    }

    // Handle canceling the matchup (for owner)
    @MainActor
    func cancelMatchup() async -> Bool {
        do {
            _ = try await matchupService.cancelMatchup(matchupId: matchupId)
            return true
        } catch {
            self.error = error
            return false
        }
    }

    private func setupNotificationObservers() {
        // Refresh when user profile is updated
        NotificationCenter.default.publisher(for: .userProfileUpdated)
            .compactMap { $0.object as? UserProfile }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] details in
                Task {
                    await self?.loadData(uploadHealthData: false)
                }
            }
            .store(in: &cancellables)

        // Refresh when a matchup is updated
        NotificationCenter.default.publisher(for: .matchupUpdated)
            .compactMap { $0.object as? MatchupDetails }
            .filter { $0.id == self.matchupId }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] details in
                self?.matchupDetails = details
            }
            .store(in: &cancellables)

        // Refresh when a user is removed
        NotificationCenter.default.publisher(for: .matchupUserRemoved)
            .compactMap { $0.object as? String }
            .filter { $0 == self.matchupId }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.loadData()
                }
            }
            .store(in: &cancellables)

        // Refresh when a matchup is canceled
        NotificationCenter.default.publisher(for: .matchupCanceled)
            .compactMap { $0.object as? Matchup }
            .filter { $0.id == self.matchupId }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] matchup in
                guard let self = self else { return }

                if var details = self.matchupDetails {
                    details.status = matchup.status
                    self.matchupDetails = details
                }
            }
            .store(in: &cancellables)

        // Matchup invite sent observer
        NotificationCenter.default.publisher(for: .matchupInviteSent)
            .compactMap { $0.object as? MatchupInvite }
            .filter { $0.matchupId == self.matchupId }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] matchupInvite in
                guard let self = self else { return }

                // Only add the invite if it doesn't already exist in the matchup
                if var details = self.matchupDetails {
                    if !details.invites.contains(where: {
                        $0.inviteCode == matchupInvite.inviteCode
                    }) {
                        details.invites.append(matchupInvite)
                        self.matchupDetails = details  // Update the published property to trigger UI refresh
                    }
                }
            }
            .store(in: &cancellables)

        // Matchup invite deleted observer
        NotificationCenter.default.publisher(for: .matchupInviteDeleted)
            .compactMap { $0.object as? MatchupInvite }
            .filter { $0.matchupId == self.matchupId }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] matchupInvite in
                guard let self = self else { return }

                if var details = self.matchupDetails {
                    details.invites.removeAll {
                        $0.inviteCode == matchupInvite.inviteCode
                    }
                    self.matchupDetails = details  // Update the published property to trigger UI refresh
                }
            }
            .store(in: &cancellables)
    }
}
