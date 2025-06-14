import Combine
import Foundation

class MatchupCardViewModel: ObservableObject, Identifiable {
    @Published var matchup: MatchupDetails?
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

    private func setupNotificationObservers() {
        // Refresh when user profile is updated
        NotificationCenter.default.publisher(for: .userProfileUpdated)
            .compactMap { $0.object as? UserProfile }
            .filter { [weak self] profile in
                guard let self = self, let details = self.matchup else {
                    return false
                }
                // Only process notification if this user is in the matchup
                return details.teams.flatMap { $0.users }.contains {
                    $0.id == profile.userSummary.id
                }
            }
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
                self?.matchup = details
            }
            .store(in: &cancellables)

        // Refresh when a user is removed
        NotificationCenter.default.publisher(for: .matchupUserRemoved)
            .compactMap { $0.object as? String }
            .filter { $0 == self.matchupId }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.loadData(uploadHealthData: false)
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

                if var details = self.matchup {
                    details.status = matchup.status
                    self.matchup = details
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
                if var details = self.matchup {
                    if !details.invites.contains(where: {
                        $0.inviteCode == matchupInvite.inviteCode
                    }) {
                        details.invites.append(matchupInvite)
                        self.matchup = details  // Update the published property to trigger UI refresh
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

                if var details = self.matchup {
                    details.invites.removeAll {
                        $0.inviteCode == matchupInvite.inviteCode
                    }
                    self.matchup = details  // Update the published property to trigger UI refresh
                }
            }
            .store(in: &cancellables)

        // Refresh when health data is updated
        NotificationCenter.default.publisher(for: .healthDataUpdated)
            .compactMap { $0.object as? MatchupDetails }
            .filter { $0.id == self.matchupId }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedMatchup in
                AppLogger.info("MatchupCard received health data update for matchup \(updatedMatchup.id)", category: .ui)
                self?.matchup = updatedMatchup
            }
            .store(in: &cancellables)

        // Refresh when workouts are recorded
        NotificationCenter.default.publisher(for: .workoutsRecorded)
            .compactMap { $0.object as? MatchupDetails }
            .filter { $0.id == self.matchupId }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] matchupWithWorkouts in
                AppLogger.info("MatchupCard received workouts recorded notification for matchup \(matchupWithWorkouts.id)", category: .ui)
                // Reload the full matchup data to get updated measurements
                Task { [weak self] in
                    await self?.loadData(uploadHealthData: false)
                }
            }
            .store(in: &cancellables)
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
            Date().timeIntervalSince(requestedTime) < 60
        {
            return
        }

        // Only load data if it hasn't been loaded in the last 10 minutes or if matchupDetails is nil
        if matchup == nil || dataLoadedTime == nil
            || Date().timeIntervalSince(dataLoadedTime!) > 600
        {
            // Mark that we've requested data
            dataRequestedTime = Date()
            await loadData(uploadHealthData: true)
        }
    }

    @MainActor
    func loadData(uploadHealthData: Bool) async {
        isLoading = true
        error = nil

        do {
            // First, get the matchup details
            let matchup = try await matchupService.getMatchup(
                matchupId: matchupId,
            )

            self.matchup = matchup
            self.dataLoadedTime = Date()
            self.isLoading = false

            // If the matchup is active, update the health data in background
            let isCurrentUserInMatchup = matchup.teams.flatMap { $0.users }
                .contains { $0.id == userSession.userId }

            if matchup.status == .active && isCurrentUserInMatchup
                && uploadHealthData
            {
                // Trigger health data update - UI will be updated via notifications
                AppLogger.info("MatchupCard triggering health data update for matchup \(matchup.id)", category: .ui)
                healthKitDataManager.updateAndUploadHealthData(matchupDetail: matchup, requestType: .userInitiated)
            }
        } catch {
            AppLogger.error(
                "Error loading matchup details: \(error)",
                category: .network
            )
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
                userId: userId
            )
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
}
