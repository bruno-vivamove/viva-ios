import Foundation

@MainActor
class FriendsViewModel: ObservableObject {
    private let friendService: FriendService
    
    @Published var friendInvites: [User] = []
    @Published var friends: [User] = []
    @Published var isLoading = false
    @Published var error: String?
    
    init(friendService: FriendService) {
        self.friendService = friendService
    }
    
    func loadData() async {
        isLoading = true
        error = nil
        
        do {
            // Load received friend requests
            friendInvites = try await friendService.getFriendRequestsReceived()
            
            // Load friends
            friends = try await friendService.getFriends()
        } catch {
            print("Error loading friends: \(error)")
            self.error = "Failed to load friends. Please try again."
        }
        
        isLoading = false
    }
    
    func acceptFriendRequest(userId: String) async {
        do {
            try await friendService.acceptFriendRequest(userId: userId)
            await loadData() // Reload data after accepting
        } catch {
            self.error = "Failed to accept friend request. Please try again."
        }
    }
    
    func declineFriendRequest(userId: String) async {
        do {
            try await friendService.declineFriendRequest(userId: userId)
            await loadData() // Reload data after declining
        } catch {
            self.error = "Failed to decline friend request. Please try again."
        }
    }
}
