import Foundation

@MainActor
class MatchupInviteCoordinator: ObservableObject {
    private let matchupService: MatchupService
    private let friendService: FriendService
    private let userService: UserService
    private let searchDebouncer = SearchDebouncer()

    @Published var searchResults: [User] = []
    @Published var friends: [User] = []
    @Published var invitedFriends: Set<String> = []
    @Published var searchQuery: String?
    @Published var isLoading = false
    @Published var error: String?
    @Published var preferredSide: MatchupUser.Side?

    private var leftSideUsers: Int = 0
    private var rightSideUsers: Int = 0
    private var usersPerSide: Int = 1

    init(
        matchupService: MatchupService,
        friendService: FriendService,
        userService: UserService
    ) {
        self.matchupService = matchupService
        self.friendService = friendService
        self.userService = userService
    }

    func loadData(matchupId: String) async {
        isLoading = true
        error = nil

        do {
            // Load matchup data
            let matchup = try await matchupService.getMatchup(
                matchupId: matchupId)
            leftSideUsers = matchup.leftUsers.count
            rightSideUsers = matchup.rightUsers.count
            usersPerSide = matchup.usersPerSide
            invitedFriends = Set(matchup.invites.compactMap { $0.user?.id })

            // Load friends list
            friends = try await friendService.getFriends()

        } catch {
            self.error = "Failed to load matchup data. Please try again."
        }

        isLoading = false
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
            self.error = "Failed to search users. Please try again."
        }

        isLoading = false
    }

    func inviteFriend(
        userId: String, matchupId: String, side: MatchupUser.Side?
    ) async {
        do {
            // Convert the side enum to string for the API
            let sideString = side == .left ? "L" : "R"
            let matchupInvite = try await matchupService.createInvite(
                matchupId: matchupId,
                side: sideString,
                userId: userId
            )
            invitedFriends.insert(userId)
        } catch {
            self.error = "Failed to invite user. Please try again."
        }
    }

    func deleteInvite(userId: String, matchupId: String) async {
        do {
            // First get all invites to find the invite code for this user
            let invites = try await matchupService.getMatchupInvites(
                matchupId: matchupId)
            if let matchupInvite = invites.first(where: { $0.user?.id == userId }) {
                try await matchupService.deleteInvite(matchupInvite)
                invitedFriends.remove(userId)
            }
        } catch {
            self.error = "Failed to delete invite. Please try again."
        }
    }

    func hasOpenPosition(side: MatchupUser.Side) -> Bool {
        switch side {
        case .left:
            return leftSideUsers < usersPerSide
        case .right:
            return rightSideUsers < usersPerSide
        }
    }

    func setPreferredSide(_ side: MatchupUser.Side) {
        preferredSide = side
    }

    func sendFriendRequest(userId: String) async {
        do {
            try await friendService.sendFriendRequest(userId: userId)

            // Update the friend status in both search results and friends lists
            updateUserFriendStatus(userId: userId, newStatus: .requestSent)

            // If user exists in either list, notify FriendsView about the new request
            if let user = searchResults.first(where: { $0.id == userId })
                ?? friends.first(where: { $0.id == userId })
            {
                let updatedUser = User(
                    id: user.id,
                    displayName: user.displayName,
                    imageUrl: user.imageUrl,
                    friendStatus: .requestSent
                )

                NotificationCenter.default.post(
                    name: .friendRequestSent,
                    object: updatedUser
                )
            }
        } catch {
            self.error = "Failed to send friend request. Please try again."
        }
    }

    private func updateUserFriendStatus(userId: String, newStatus: FriendStatus)
    {
        // Update in search results
        if let index = searchResults.firstIndex(where: { $0.id == userId }) {
            searchResults[index] = User(
                id: searchResults[index].id,
                displayName: searchResults[index].displayName,
                imageUrl: searchResults[index].imageUrl,
                friendStatus: newStatus
            )
        }

        // Update in friends list
        if let index = friends.firstIndex(where: { $0.id == userId }) {
            friends[index] = User(
                id: friends[index].id,
                displayName: friends[index].displayName,
                imageUrl: friends[index].imageUrl,
                friendStatus: newStatus
            )
        }
    }

    func cleanup() {
        searchDebouncer.cancel()
    }
}
