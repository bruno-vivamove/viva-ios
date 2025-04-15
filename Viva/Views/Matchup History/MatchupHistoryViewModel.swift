import Combine
import SwiftUI

final class MatchupHistoryViewModel: ObservableObject {
    @Published var selectedMatchup: Matchup?
    @Published var userStats: UserStats?
    @Published var matchupStats: [MatchupStats] = []
    @Published var completedMatchups: [Matchup] = []
    @Published var isLoading: Bool = false
    @Published var error: String?

    private let matchupService: MatchupService
    private var cancellables = Set<AnyCancellable>()

    init(matchupService: MatchupService) {
        self.matchupService = matchupService
        setupNotificationObservers()
    }

    private func setupNotificationObservers() {
        // Matchup updated observer
        NotificationCenter.default.publisher(for: .matchupUpdated)
            .compactMap { $0.object as? MatchupDetails }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] matchupDetails in
                let updatedMatchup = matchupDetails.asMatchup

                // Update completed matchups if status changed to completed
                if updatedMatchup.status == .completed {
                    self?.handleMatchupStatusChanged(updatedMatchup)
                }
            }
            .store(in: &cancellables)

        // Matchup creation flow completed observer
        NotificationCenter.default.publisher(
            for: .matchupCreationFlowCompleted
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] notification in
            guard let matchupDetails = notification.object as? MatchupDetails
            else {
                return
            }

            // Get the source from userInfo if available
            if let userInfo = notification.userInfo,
                let source = userInfo["source"] as? String
            {

                // Navigate if source is 'history'
                if source == "history" {
                    // TODO need to navigate to the new matchup details
                    self?.selectedMatchup = matchupDetails.asMatchup
                }
            }
        }
        .store(in: &cancellables)

        // Matchup canceled observer
        NotificationCenter.default.publisher(for: .matchupCanceled)
            .compactMap { $0.object as? Matchup }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] matchup in
                self?.handleMatchupCanceled(matchup)
            }
            .store(in: &cancellables)
    }

    private func handleMatchupStatusChanged(_ updatedMatchup: Matchup) {
        // If the matchup status changed to completed, add it to completedMatchups
        if updatedMatchup.status == .completed {
            if !completedMatchups.contains(where: { $0.id == updatedMatchup.id }
            ) {
                completedMatchups.append(updatedMatchup)
            } else {
                // Update existing matchup
                if let index = completedMatchups.firstIndex(where: {
                    $0.id == updatedMatchup.id
                }) {
                    completedMatchups[index] = updatedMatchup
                }
            }

            // Also refresh stats since they may have changed
            Task {
                do {
                    let response =
                        try await matchupService.getMatchupStats()
                    self.userStats = response.userStats
                    self.matchupStats = response.matchupStats
                } catch {
                    // Ignore errors when refreshing in background
                }
            }
        }
    }

    private func handleMatchupCanceled(_ matchup: Matchup) {
        // Remove from completed matchups if it exists
        completedMatchups.removeAll { $0.id == matchup.id }

        if self.selectedMatchup?.id == matchup.id {
            self.selectedMatchup = nil
        }
    }

    @MainActor
    func loadMatchupStats() async {
        isLoading = true
        error = nil

        do {
            // Load matchup stats and all matchups concurrently
            async let statsTask = matchupService.getMatchupStats()
            async let matchupsTask = matchupService.getMyMatchups(
                filter: .COMPLETED_ONLY
            )

            // Await all results
            let (statsResponse, matchupsResponse) = try await (
                statsTask, matchupsTask
            )

            // Update the published properties
            userStats = statsResponse.userStats
            matchupStats = statsResponse.matchupStats

            // Use the completed matchups from the response
            completedMatchups = matchupsResponse.matchups

            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
}
