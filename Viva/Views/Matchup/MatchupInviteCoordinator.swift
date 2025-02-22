import SwiftUI

@MainActor
class MatchupInviteCoordinator: ObservableObject {
    let matchupService: MatchupService
    let friendService: FriendService
    let userService: UserService
    private let searchDebouncer = SearchDebouncer()
    
    @Published var friends: [User] = []
    @Published var searchResults: [User] = []
    @Published var searchQuery: String?
    @Published var invitedFriends: Set<String> = []
    @Published var matchupDetails: MatchupDetails?
    @Published var isLoading = false
    @Published var error: Error?

    private var preferredSide: MatchupUser.Side?
    
    init(matchupService: MatchupService, friendService: FriendService, userService: UserService) {
        self.matchupService = matchupService
        self.friendService = friendService
        self.userService = userService
    }

    func setPreferredSide(_ side: MatchupUser.Side) {
        self.preferredSide = side
    }

    func loadData(matchupId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let friendsTask = friendService.getFriends()
            async let matchupTask = matchupService.getMatchup(matchupId: matchupId)
            
            let (loadedFriends, loadedMatchup) = try await (friendsTask, matchupTask)
            self.friends = loadedFriends
            self.matchupDetails = loadedMatchup
        } catch {
            self.error = error
        }
    }

    func debouncedSearch(query: String) {
        searchDebouncer.debounce { [weak self] in
            await self?.searchUsers(query: query)
        }
    }
    
    private func searchUsers(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            searchQuery = nil
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            searchResults = try await userService.searchUsers(query: query)
            searchQuery = query
        } catch {
            self.error = error
        }
        
        isLoading = false
    }

    func inviteFriend(userId: String, matchupId: String, side: MatchupUser.Side? = nil) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let finalSide = side ?? preferredSide ?? .left
            _ = try await matchupService.createInvite(
                matchupId: matchupId,
                side: finalSide.rawValue,
                userId: userId
            )
            invitedFriends.insert(userId)
            matchupDetails = try await matchupService.getMatchup(matchupId: matchupId)
        } catch {
            self.error = error
        }
    }
    
    func deleteInvite(userId: String, matchupId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // First we need to get the invite code for this user/matchup
            let invites = try await matchupService.getMatchupInvites(matchupId: matchupId)
            guard let invite = invites.first(where: { $0.user?.id == userId }) else {
                return
            }
            
            // Delete the invite
            try await matchupService.deleteInvite(matchupId: matchupId, inviteCode: invite.inviteCode)
            
            // Update local state
            invitedFriends.remove(userId)
            matchupDetails = try await matchupService.getMatchup(matchupId: matchupId)
        } catch {
            self.error = error
        }
    }
    
    func hasOpenPosition(side: MatchupUser.Side) -> Bool {
        guard let matchup = matchupDetails else { return false }
        let users = side == .left ? matchup.leftUsers : matchup.rightUsers
        return users.count < matchup.usersPerSide
    }
    
    func cleanup() {
        searchDebouncer.cancel()
    }
}
