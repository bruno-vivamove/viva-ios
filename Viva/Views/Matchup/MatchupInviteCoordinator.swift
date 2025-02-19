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

    init(matchupService: MatchupService, friendService: FriendService, userService: UserService) {
        self.matchupService = matchupService
        self.friendService = friendService
        self.userService = userService
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

    func inviteFriend(userId: String, matchupId: String, side: MatchupUser.Side) async {
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await matchupService.createInvite(
                matchupId: matchupId,
                side: side.rawValue,
                userId: userId
            )
            invitedFriends.insert(userId)
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
