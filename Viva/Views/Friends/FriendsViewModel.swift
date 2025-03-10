import Foundation

@MainActor
class FriendsViewModel: ObservableObject {
    // Services
    private let friendService: FriendService
    private let userService: UserService
    private let searchDebouncer = SearchDebouncer()
    
    // State for user session
    let userSession: UserSession
    
    // State for friends list
    @Published var friendInvites: [User] = []
    @Published var sentInvites: [User] = []
    @Published var friends: [User] = []
    
    // State for search
    @Published var searchResults: [User] = []
    @Published var isSearchMode = false
    @Published var searchQuery: String?
    
    // Shared state
    @Published var isLoading = false
    @Published var error: String?
    
    init(friendService: FriendService, userService: UserService, userSession: UserSession) {
        self.friendService = friendService
        self.userService = userService
        self.userSession = userSession
    }
    
    // MARK: - Search Functions
    
    func debouncedSearch(query: String) {
        searchDebouncer.debounce { [weak self] in
            await self?.searchUsers(query: query)
        }
    }
    
    private func searchUsers(query: String) async {
        guard !query.isEmpty else {
            await clearSearchResults()
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            searchResults = try await userService.searchUsers(query: query)
            searchQuery = query
            isSearchMode = true
        } catch {
            self.error = "Failed to search users. Please try again."
        }
        
        isLoading = false
    }
    
    func clearSearchResults() async {
        searchResults = []
        searchQuery = nil
        isSearchMode = false
        error = nil
    }
    
    func sendFriendRequest(userId: String) async {
        do {
            try await friendService.sendFriendRequest(userId: userId)
            
            // Update the local state to reflect the sent request
            if let index = searchResults.firstIndex(where: { $0.id == userId }) {
                let updatedUser = User(
                    id: searchResults[index].id,
                    displayName: searchResults[index].displayName,
                    imageUrl: searchResults[index].imageUrl,
                    friendStatus: .requestSent
                )
                searchResults[index] = updatedUser
                
                // Ensure the user is also in the sentInvites list
                if !sentInvites.contains(where: { $0.id == userId }) {
                    sentInvites.append(updatedUser)
                }
                
                // Notify about the new sent request
                NotificationCenter.default.post(
                    name: .friendRequestSent,
                    object: updatedUser
                )
            }
        } catch {
            self.error = "Failed to send friend request. Please try again."
        }
    }
    
    // MARK: - Friends List Functions
    
    func loadFriendsData() async {
        isLoading = true
        error = nil
        
        do {
            // Load all data concurrently
            async let receivedInvitesTask = friendService.getFriendRequestsReceived()
            async let sentInvitesTask = friendService.getFriendRequestsSent()
            async let friendsTask = friendService.getFriends()
            
            // Await all results
            let (receivedInvites, sentInvites, friends) = try await (
                receivedInvitesTask,
                sentInvitesTask,
                friendsTask
            )
            
            self.friendInvites = receivedInvites
            self.sentInvites = sentInvites
            self.friends = friends
        } catch {
            self.error = "Failed to load friends. Please try again."
        }
        
        isLoading = false
    }
    
    func acceptFriendRequest(userId: String) async {
        do {
            try await friendService.acceptFriendRequest(userId: userId)
            await loadFriendsData() // Reload after accepting since it affects multiple lists
        } catch {
            self.error = "Failed to accept friend request. Please try again."
        }
    }
    
    func declineFriendRequest(userId: String) async {
        do {
            try await friendService.declineFriendRequest(userId: userId)
            // Remove the invite locally
            friendInvites.removeAll { $0.id == userId }
        } catch {
            self.error = "Failed to decline friend request. Please try again."
            await loadFriendsData() // Reload on error to ensure consistency
        }
    }
    
    func deleteFriend(userId: String) async {
        do {
            try await friendService.deleteFriend(userId: userId)
            // Remove the friend locally
            friends.removeAll { $0.id == userId }
        } catch {
            self.error = "Failed to delete friend. Please try again."
            await loadFriendsData() // Reload on error to ensure consistency
        }
    }
    
    func cancelFriendRequest(userId: String) async {
        do {
            try await friendService.cancelFriendRequest(userId: userId)
            
            // Remove the sent invite locally
            sentInvites.removeAll { $0.id == userId }
            
            // If the user is in search results, update their status
            if let index = searchResults.firstIndex(where: { $0.id == userId }) {
                searchResults[index] = User(
                    id: searchResults[index].id,
                    displayName: searchResults[index].displayName,
                    imageUrl: searchResults[index].imageUrl,
                    friendStatus: .notFriend
                )
            }
        } catch {
            self.error = "Failed to cancel friend request. Please try again."
            await loadFriendsData() // Reload on error to ensure consistency
        }
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        searchDebouncer.cancel()
    }
}
