import Combine
import Foundation
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    let userSession: UserSession
    let matchupService: MatchupService

    @Published var matchups: [Matchup] = []
    @Published var receivedInvites: [MatchupInvite] = []
    @Published var sentInvites: [MatchupInvite] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var selectedMatchup: Matchup?

    // Data tracking properties
    var dataLoadedTime: Date? = nil
    private var dataRequestedTime: Date?
    private var cancellables = Set<AnyCancellable>()

    var isEmpty: Bool {
        matchups.isEmpty && receivedInvites.isEmpty && sentInvites.isEmpty
    }

    var activeMatchups: [Matchup] {
        matchups.filter { $0.status == .active }
    }

    var pendingMatchups: [Matchup] {
        matchups.filter { $0.status == .pending }
    }

    var completedMatchups: [Matchup] {
        matchups.filter { $0.status == .completed }
    }

    var allInvites: [MatchupInvite] {
        receivedInvites + sentInvites
    }

    var hasInvites: Bool {
        !receivedInvites.isEmpty || !sentInvites.isEmpty
    }

    init(
        userSession: UserSession,
        matchupService: MatchupService
    ) {
        self.userSession = userSession
        self.matchupService = matchupService

        setupNotificationObservers()
    }
    
    // Set error only if it's not a network error
    func setError(_ error: Error) {
        // Only store the error if it's not a NetworkClientError
        if !(error is NetworkClientError) {
            self.error = error
        }
    }
    
    // Clear the current error
    func clearError() {
        error = nil
    }
    
    func loadInitialDataIfNeeded() async {
        // Don't load if we've requested data in the last minute, regardless of result
        if let requestedTime = dataRequestedTime, 
           Date().timeIntervalSince(requestedTime) < 60 {
            return
        }
        
        // Only load data if it hasn't been loaded in the last 10 minutes
        if dataLoadedTime == nil
            || Date().timeIntervalSince(dataLoadedTime!) > 600
        {
            // Mark that we've requested data
            dataRequestedTime = Date()
            await loadData()
        }
    }

    func loadData() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            // Load matchups and both types of invites concurrently
            async let matchupsTask = matchupService.getMyMatchups(filter: .UNFINALIZED, syncMatchupMembers: true)
            async let receivedInvitesTask = matchupService.getMyInvites()
            async let sentInvitesTask = matchupService.getSentInvites()

            // Await all results
            let (fetchedMatchupsResponse, fetchedReceivedInvites, fetchedSentInvites) =
                try await (matchupsTask, receivedInvitesTask, sentInvitesTask)

            // Update the published properties
            self.matchups = fetchedMatchupsResponse.matchups
            self.receivedInvites = fetchedReceivedInvites
            self.sentInvites = fetchedSentInvites

            // Update the time when data was successfully loaded
            self.dataLoadedTime = Date()
        } catch {
            self.setError(error)
        }

        isLoading = false
    }

    func createMatchup(_ matchup: Matchup) {
        // Implementation missing in original code
    }

    func handleMatchCreated(_ matchup: Matchup) {
        matchups.insert(matchup, at: 0)
    }

    func handleMatchupCanceled(_ matchup: Matchup) {
        // Remove the matchup
        matchups.removeAll { $0.id == matchup.id }

        // Remove any associated invites
        receivedInvites.removeAll { $0.matchupId == matchup.id }
        sentInvites.removeAll { $0.matchupId == matchup.id }
    }

    func handleMatchupUpdated(_ matchupDetails: MatchupDetails) {
        // If the matchup is finalized and completed, remove it from the list
        if matchupDetails.status == .completed && matchupDetails.finalized {
            matchups.removeAll(where: { $0.id == matchupDetails.id })
            return
        }
        
        // Otherwise, update the matchup in the list
        let updatedMatchup = matchupDetails.asMatchup
        if let index = matchups.firstIndex(where: { $0.id == updatedMatchup.id }) {
            matchups[index] = updatedMatchup
        }
    }

    func handleInviteSent(_ matchupInvite: MatchupInvite) {
        // Add to sent invites collection
        self.sentInvites.insert(matchupInvite, at: 0)

        // Update the corresponding matchup by adding the invite
        if let matchupIndex = matchups.firstIndex(where: {
            $0.id == matchupInvite.matchupId
        }) {
            var updatedMatchup = matchups[matchupIndex]

            // Only add the invite if it doesn't already exist in the matchup
            if !updatedMatchup.invites.contains(where: {
                $0.inviteCode == matchupInvite.inviteCode
            }) {
                updatedMatchup.invites.append(matchupInvite)
            }

            // Update the matchup in the array
            matchups[matchupIndex] = updatedMatchup

            // Also update selectedMatchup if it's the same matchup
            if let selectedMatchup = selectedMatchup,
                selectedMatchup.id == matchupInvite.matchupId
            {
                var updated = selectedMatchup
                if !updated.invites.contains(where: {
                    $0.inviteCode == matchupInvite.inviteCode
                }) {
                    updated.invites.append(matchupInvite)
                }
                self.selectedMatchup = updated
            }
        }
    }

    func deleteInvite(_ matchupInvite: MatchupInvite) async {
        do {
            try await matchupService.deleteInvite(matchupInvite)
        } catch {
            self.setError(error)
        }
    }

    func handleInviteDeleted(_ invite: MatchupInvite) {
        // Remove the invite from received/sent invites
        receivedInvites.removeAll { $0.inviteCode == invite.inviteCode }
        sentInvites.removeAll { $0.inviteCode == invite.inviteCode }

        // Update the corresponding matchup by removing the invite
        if let matchupIndex = matchups.firstIndex(where: {
            $0.id == invite.matchupId
        }) {
            var updatedMatchup = matchups[matchupIndex]
            updatedMatchup.invites.removeAll {
                $0.inviteCode == invite.inviteCode
            }
            matchups[matchupIndex] = updatedMatchup

            // Also update selectedMatchup if it's the same matchup
            if let selectedMatchup = selectedMatchup,
                selectedMatchup.id == invite.matchupId
            {
                var updated = selectedMatchup
                updated.invites.removeAll { $0.inviteCode == invite.inviteCode }
                self.selectedMatchup = updated
            }
        }
    }

    func acceptInvite(_ invite: MatchupInvite) async {
        do {
            try await matchupService.acceptInvite(invite)
        } catch {
            self.setError(error)
        }
    }

    func handleInviteAccepted(_ invite: MatchupInvite) async {
        do {
            let matchupDetails = try await matchupService.getMatchup(
                matchupId: invite.matchupId)
            let newMatchup = matchupDetails.asMatchup

            // Add the new matchup to the view model
            self.matchups.append(newMatchup)

            // Remove the invite from received invites
            self.receivedInvites.removeAll(where: {
                $0.matchupId == newMatchup.id
            })
            self.selectedMatchup = newMatchup
        } catch {
            self.setError(error)
        }
    }

    private func setupNotificationObservers() {
        // Matchup created observer
        NotificationCenter.default.publisher(for: .matchupCreated)
            .compactMap { $0.object as? MatchupDetails }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] matchupDetails in
                self?.handleMatchCreated(matchupDetails.asMatchup)
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

        // Matchup updated observer
        NotificationCenter.default.publisher(for: .matchupUpdated)
            .compactMap { $0.object as? MatchupDetails }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] matchupDetails in
                self?.handleMatchupUpdated(matchupDetails)
            }
            .store(in: &cancellables)

        // Matchup invite sent observer
        NotificationCenter.default.publisher(for: .matchupInviteSent)
            .compactMap { $0.object as? MatchupInvite }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] matchupInvite in
                self?.handleInviteSent(matchupInvite)
            }
            .store(in: &cancellables)

        // Matchup invite deleted observer
        NotificationCenter.default.publisher(for: .matchupInviteDeleted)
            .compactMap { $0.object as? MatchupInvite }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] matchupInvite in
                self?.handleInviteDeleted(matchupInvite)
            }
            .store(in: &cancellables)

        // Matchup invite accepted observer
        NotificationCenter.default.publisher(for: .matchupInviteAccepted)
            .compactMap { $0.object as? MatchupInvite }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] matchupInvite in
                guard let self = self else { return }

                self.receivedInvites.removeAll(where: {
                    $0.inviteCode == matchupInvite.inviteCode
                })
                self.sentInvites.removeAll(where: {
                    $0.inviteCode == matchupInvite.inviteCode
                })

                Task {
                    do {
                        self.selectedMatchup =
                            try await self.matchupService.getMatchup(
                                matchupId: matchupInvite.matchupId
                            ).asMatchup
                    } catch {
                        self.setError(error)
                    }
                }
            }
            .store(in: &cancellables)

        // Matchup creation flow completed observer
        NotificationCenter.default.publisher(
            for: .matchupCreationFlowCompleted
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] notification in
            guard let matchupDetails = notification.object as? MatchupDetails else {
                return
            }
            
            // Get the source from userInfo if available
            if let userInfo = notification.userInfo,
               let source = userInfo["source"] as? String {
               
                // Navigate if source is 'home'
                if source == "home" {
                    self?.selectedMatchup = matchupDetails.asMatchup
                }
            }
        }
        .store(in: &cancellables)
    }
}
