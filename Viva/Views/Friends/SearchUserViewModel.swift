import Foundation

@MainActor
class SearchUserViewModel: ObservableObject {
    private let userService: UserService
    private let friendService: FriendService
    private let searchDebouncer = SearchDebouncer()
    
    @Published var searchResults: [User] = []
    @Published var searchResultsQuery: String?
    @Published var isLoading = false
    @Published var error: String?
    
    init(userService: UserService, friendService: FriendService) {
        self.userService = userService
        self.friendService = friendService
    }
    
    func debouncedSearch(query: String) {
        searchDebouncer.debounce { [weak self] in
            await self?.searchUsers(query: query)
        }
    }
    
    private func searchUsers(query: String) async {
        guard !query.isEmpty else {
            await clearResults()
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            searchResults = try await userService.searchUsers(query: query)
            searchResultsQuery = query
        } catch {
            self.error = "Failed to search users. Please try again."
        }
        
        isLoading = false
    }
    
    func cleanup() {
        searchDebouncer.cancel()
    }
    
    func sendFriendRequest(userId: String) async {
        do {
            try await friendService.sendFriendRequest(userId: userId)
            // Update the local state to reflect the sent request
            if let index = searchResults.firstIndex(where: { $0.id == userId }) {
                searchResults[index] = User(
                    id: searchResults[index].id,
                    displayName: searchResults[index].displayName,
                    imageUrl: searchResults[index].imageUrl,
                    friendStatus: .requestSent
                )
            }
        } catch {
            self.error = "Failed to send friend request. Please try again."
        }
    }
    
    func cancelFriendRequest(userId: String) async {
        do {
            try await friendService.cancelFriendRequest(userId: userId)
            // Update the local state to reflect the cancelled request
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
        }
    }
    
    func clearResults() async {
        searchResults = []
        searchResultsQuery = nil
        error = nil
    }
}
