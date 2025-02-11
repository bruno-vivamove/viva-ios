import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    private let matchupService: MatchupService
    
    @Published var matchups: [Matchup] = []
    @Published var receivedInvites: [MatchupInvite] = []
    @Published var sentInvites: [MatchupInvite] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private var hasLoadedInitialData = false
    
    init(matchupService: MatchupService) {
        self.matchupService = matchupService
    }
    
    func loadInitialDataIfNeeded() async {
        guard !hasLoadedInitialData else { return }
        await loadData()
        hasLoadedInitialData = true
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
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func refresh() async {
        await loadData()
    }
}
