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

    var dataRefreshedTime: Date? = nil

    init(
        userSession: UserSession,
        matchupService: MatchupService
    ) {
        self.userSession = userSession
        self.matchupService = matchupService

        // Matchup created observer
        NotificationCenter.default.addObserver(
            forName: .matchupCreated,
            object: nil,
            queue: .main
        ) { notification in
            if let matchupDetails = notification.object as? MatchupDetails {
                Task { @MainActor in
                    self.handleMatchCreated(matchupDetails.asMatchup)
                }
            }
        }

        // Matchup canceled observer
        NotificationCenter.default.addObserver(
            forName: .matchupCanceled,
            object: nil,
            queue: .main
        ) { notification in
            if let matchup = notification.object as? Matchup {
                Task { @MainActor in
                    self.handleMatchupCanceled(matchup)
                }
            }
        }

        // Matchup updated observer
        NotificationCenter.default.addObserver(
            forName: .matchupUpdated,
            object: nil,
            queue: .main
        ) { notification in
            if let matchupDetails = notification.object as? MatchupDetails {
                Task { @MainActor in
                    self.handleMatchupUpdated(matchupDetails.asMatchup)
                }
            }
        }

        // Matchup invite sent observer
        NotificationCenter.default.addObserver(
            forName: .matchupInviteSent,
            object: nil,
            queue: .main
        ) { notification in
            if let matchupInvite = notification.object as? MatchupInvite {
                Task { @MainActor in
                    self.handleInviteSent(matchupInvite)
                }
            }
        }

        // Matchup invite deleted observer
        NotificationCenter.default.addObserver(
            forName: .matchupInviteDeleted,
            object: nil,
            queue: .main
        ) { notification in
            if let matchupInvite = notification.object as? MatchupInvite {
                Task { @MainActor in
                    self.handleInviteDeleted(matchupInvite)
                }
            }
        }

        // Matchup invite accepted observer
        NotificationCenter.default.addObserver(
            forName: .matchupInviteAccepted,
            object: nil,
            queue: .main
        ) { notification in
            if let matchupInvite = notification.object as? MatchupInvite {
                Task { @MainActor in
                    self.receivedInvites.removeAll(where: {
                        $0.matchupId == matchupInvite.matchupId
                    })
                    self.sentInvites.removeAll(where: {
                        $0.matchupId == matchupInvite.matchupId
                    })

                    do {
                        self.selectedMatchup =
                        try await self.matchupService.getMatchup(
                                matchupId: matchupInvite.matchupId
                            ).asMatchup
                    } catch {
                        self.error = error
                    }
                }
            }
        }

        // Matchup invite accepted observer
        NotificationCenter.default.addObserver(
            forName: .homeScreenMatchupCreationCompleted,
            object: nil,
            queue: .main
        ) { notification in
            if let matchupDetails = notification.object as? MatchupDetails {
                Task { @MainActor in
                    self.selectedMatchup = matchupDetails.asMatchup
                }
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(
            self, name: .matchupCreated, object: nil)
        NotificationCenter.default.removeObserver(
            self, name: .matchupCanceled, object: nil)
        NotificationCenter.default.removeObserver(
            self, name: .matchupUpdated, object: nil)
        NotificationCenter.default.removeObserver(
            self, name: .matchupInviteSent, object: nil)
        NotificationCenter.default.removeObserver(
            self, name: .matchupInviteDeleted, object: nil)
        NotificationCenter.default.removeObserver(
            self, name: .matchupInviteAccepted, object: nil)
        NotificationCenter.default.removeObserver(
            self, name: .homeScreenMatchupCreationCompleted, object: nil)
    }

    func loadInitialDataIfNeeded() async {
        // Only load data if it hasn't been refreshed in the last 10 minutes
        if dataRefreshedTime == nil
            || Date().timeIntervalSince(dataRefreshedTime!) > 600
        {
            await loadData()
        }
    }

    func loadData() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            // Load matchups and both types of invites concurrently
            async let matchupsTask = matchupService.getMyMatchups()
            async let receivedInvitesTask = matchupService.getMyInvites()
            async let sentInvitesTask = matchupService.getSentInvites()

            // Await all results
            let (fetchedMatchups, fetchedReceivedInvites, fetchedSentInvites) =
                try await (matchupsTask, receivedInvitesTask, sentInvitesTask)

            // Update the published properties
            self.matchups = fetchedMatchups
            self.receivedInvites = fetchedReceivedInvites
            self.sentInvites = fetchedSentInvites

            self.dataRefreshedTime = Date()
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func createMatchup(_ matchup: Matchup) {

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

    func handleMatchupUpdated(_ updatedMatchup: Matchup) {
        if let index = matchups.firstIndex(where: { $0.id == updatedMatchup.id }
        ) {
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

            matchups[matchupIndex] = updatedMatchup
        }
    }

    func deleteInvite(_ matchupInvite: MatchupInvite) async {
        do {
            try await matchupService.deleteInvite(matchupInvite)
        } catch {
            self.error = error
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
        }
    }

    func acceptInvite(_ invite: MatchupInvite) async {
        do {
            try await matchupService.acceptInvite(invite)
        } catch {
            self.error = error
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
            self.error = error
        }
    }

    var isEmpty: Bool {
        matchups.isEmpty && receivedInvites.isEmpty && sentInvites.isEmpty
    }

    var activeMatchups: [Matchup] {
        matchups.filter { $0.status == .active }
    }

    var pendingMatchups: [Matchup] {
        matchups.filter { $0.status == .pending }
    }

    var allInvites: [MatchupInvite] {
        receivedInvites + sentInvites
    }

    var hasInvites: Bool {
        !receivedInvites.isEmpty || !sentInvites.isEmpty
    }
}
