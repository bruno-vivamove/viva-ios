import Combine
import Foundation

class MatchupCardViewModel: ObservableObject {
    @Published var matchupDetails: MatchupDetails?
    @Published var isLoading: Bool = false
    @Published var error: Error?

    private let matchupId: String
    private let matchupService: MatchupService
    private let healthKitDataManager: HealthKitDataManager
    private let userSession: UserSession
    private var cancellables = Set<AnyCancellable>()

    // Add this property to track refresh time
    private var lastRefreshTime: Date?

    init(
        matchupId: String,
        matchupService: MatchupService,
        healthKitDataManager: HealthKitDataManager,
        userSession: UserSession,
        lastRefreshTime: Date? = nil
    ) {
        self.matchupId = matchupId
        self.matchupService = matchupService
        self.healthKitDataManager = healthKitDataManager
        self.userSession = userSession
        self.lastRefreshTime = lastRefreshTime
        self.isLoading = true

        // Listen for relevant notifications that should trigger a refresh
        setupNotificationObservers()

        // Load the matchup details
        Task {
            await loadMatchupDetails()
        }
    }

    // Add this method to update the refresh time
    func updateLastRefreshTime(_ newTime: Date?) {
        // Only refresh if the new time is different (and later) than the current one
        if let newTime = newTime,
            lastRefreshTime == nil || newTime > lastRefreshTime!
        {
            lastRefreshTime = newTime
            Task {
                await loadMatchupDetails()
            }
        }
    }

    @MainActor
    func loadMatchupDetails() async {
        isLoading = true
        error = nil

        do {
            // First, get the basic matchup details
            let details = try await matchupService.getMatchup(
                matchupId: matchupId)

            // If the matchup is active to update the health data
            if details.status == .active {
                healthKitDataManager.updateMatchupData(matchupDetail: details) {
                    updatedMatchup in
                    Task { @MainActor in
                        self.matchupDetails = updatedMatchup

                        // If there are updated measurements from the current user, save them
                        let userMeasurements = updatedMatchup.userMeasurements
                            .filter {
                                $0.userId == self.userSession.userId
                            }

                        if !userMeasurements.isEmpty {
                            do {
                                // Send all measurements in a single call
                                let savedMatchupDetails =
                                    try await self.matchupService
                                    .saveUserMeasurements(
                                        matchupId: self.matchupId,
                                        measurements: userMeasurements
                                    )

                                self.matchupDetails = savedMatchupDetails
                                self.isLoading = false
                            } catch {
                                print("Failed to save measurements: \(error)")
                            }
                        }
                    }
                }
            } else {
                self.matchupDetails = details
                self.isLoading = false
            }
        } catch {
            print("Error loading matchup details: \(error)")
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
                    await self?.loadMatchupDetails()
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
