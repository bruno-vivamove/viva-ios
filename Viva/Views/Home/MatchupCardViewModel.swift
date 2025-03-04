import Foundation
import Combine

class MatchupCardViewModel: ObservableObject {
    @Published var matchupDetails: MatchupDetails?
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var refreshTrigger: Bool = false
    
    private let matchupId: String
    private let matchupService: MatchupService
    private var cancellables = Set<AnyCancellable>()
    
    init(matchupId: String, matchupService: MatchupService) {
        self.matchupId = matchupId
        self.matchupService = matchupService
        
        // Listen for relevant notifications that should trigger a refresh
        setupNotificationObservers()
        
        // Load the matchup details
        Task {
            await loadMatchupDetails()
        }
    }
    
    @MainActor
    func loadMatchupDetails() async {
        isLoading = true
        error = nil
        
        do {
            matchupDetails = try await matchupService.getMatchup(matchupId: matchupId)
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    // Function to manually trigger a refresh from parent views
    @MainActor
    func refresh() async {
        await loadMatchupDetails()
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
            .sink { [weak self] details in
                self?.matchupDetails = details
            }
            .store(in: &cancellables)
        
        // Refresh when a user is removed
        NotificationCenter.default.publisher(for: .matchupUserRemoved)
            .compactMap { $0.object as? String }
            .filter { $0 == self.matchupId }
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
            .sink { [weak self] matchup in
                if let details = self?.matchupDetails {
                    // Update just the status without re-fetching
                    var updatedDetails = details
                    updatedDetails.status = matchup.status
                    self?.matchupDetails = updatedDetails
                }
            }
            .store(in: &cancellables)
    }
}
