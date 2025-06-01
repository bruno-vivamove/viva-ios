import Foundation
import Combine

@MainActor
class FriendsViewModel: ObservableObject {
    // Services
    private let friendService: FriendService
    private let userService: UserService
    private let matchupService: MatchupService
    private let searchDebouncer = SearchDebouncer()
    
    // State for user session
    let userSession: UserSession
    
    // State for friends list
    @Published var friendInvites: [UserSummary] = []
    @Published var sentInvites: [UserSummary] = []
    @Published var friends: [UserSummary] = []
    
    // State for search
    @Published var searchResults: [UserSummary] = []
    @Published var isSearchMode = false
    @Published var searchQuery: String?
    @Published var searchText: String = ""
    
    // Navigation state
    @Published var selectedUserId: String? = nil
    
    // Shared state
    @Published var isLoading = false
    @Published var error: Error?
    @Published var selectedMatchup: Matchup?
    
    // Data tracking properties
    private var dataLoadedTime: Date?
    private var dataRequestedTime: Date?
    private var cancellables = Set<AnyCancellable>()
    
    // Set error only if it's not a network error
    func setError(_ error: Error) {
        // Only store the error if it's not a NetworkClientError
        if !(error is NetworkClientError) {
            self.error = error
        }
    }
    
    init(friendService: FriendService, userService: UserService, matchupService: MatchupService, userSession: UserSession) {
        self.friendService = friendService
        self.userService = userService
        self.matchupService = matchupService
        self.userSession = userSession
        
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        // Observe friend request sent notifications
        NotificationCenter.default.publisher(for: .friendRequestSent)
            .compactMap { $0.object as? UserSummary }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sentUser in
                Task { @MainActor in
                    // Add the user to sent invites if not already present
                    if let self = self, !self.sentInvites.contains(where: {
                        $0.id == sentUser.id
                    }) {
                        self.sentInvites.append(sentUser)
                    }
                }
            }
            .store(in: &cancellables)
        
        // Observe matchup creation notifications
        NotificationCenter.default.publisher(for: .matchupCreationFlowCompleted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let matchupDetails = notification.object as? MatchupDetails,
                   let userInfo = notification.userInfo,
                   let source = userInfo["source"] as? String,
                   source == "friends" {
                    Task {
                        await MainActor.run {
                            self?.selectedMatchup = matchupDetails.asMatchup
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
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
            await loadFriendsData()
        }
    }
    
    // MARK: - Search Functions
    
    func debouncedSearch() {
        searchDebouncer.debounce { [weak self] in
            if let self = self {
                await self.searchUsers(query: self.searchText)
            }
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
            self.setError(error)
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
                let updatedUser = UserSummary(
                    id: searchResults[index].id,
                    displayName: searchResults[index].displayName,
                    caption: searchResults[index].caption,
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
            self.setError(error)
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
            
            // Update the time when data was successfully loaded
            self.dataLoadedTime = Date()
        } catch {
            self.setError(error)
        }
        
        isLoading = false
    }
    
    func acceptFriendRequest(userId: String) async {
        do {
            try await friendService.acceptFriendRequest(userId: userId)
            await loadFriendsData() // Reload after accepting since it affects multiple lists
        } catch {
            self.setError(error)
        }
    }
    
    func declineFriendRequest(userId: String) async {
        do {
            try await friendService.declineFriendRequest(userId: userId)
            // Remove the invite locally
            friendInvites.removeAll { $0.id == userId }
        } catch {
            self.setError(error)
            await loadFriendsData() // Reload on error to ensure consistency
        }
    }
    
    func deleteFriend(userId: String) async {
        do {
            try await friendService.deleteFriend(userId: userId)
            // Remove the friend locally
            friends.removeAll { $0.id == userId }
        } catch {
            self.setError(error)
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
                searchResults[index] = UserSummary(
                    id: searchResults[index].id,
                    displayName: searchResults[index].displayName,
                    caption: searchResults[index].caption,
                    imageUrl: searchResults[index].imageUrl,
                    friendStatus: .notFriend
                )
            }
        } catch {
            self.setError(error)
            await loadFriendsData() // Reload on error to ensure consistency
        }
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        searchDebouncer.cancel()
    }
}
