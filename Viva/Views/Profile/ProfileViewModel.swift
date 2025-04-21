import Foundation
import SwiftUI
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var isImageLoading = false
    @Published var errorMessage: String?
    @Published var userProfile: UserProfile?
    @Published var activeMatchups: [Matchup] = []
    @Published var selectedMatchup: Matchup?
    
    private let userSession: UserSession
    private let userService: UserService
    private let matchupService: MatchupService
    private let userId: String
    private var cancellables = Set<AnyCancellable>()
    
    init(userId: String, userSession: UserSession, userService: UserService, matchupService: MatchupService) {
        self.userId = userId
        self.userSession = userSession
        self.userService = userService
        self.matchupService = matchupService
        
        setupNotificationObservers()
    }
    
    var isCurrentUser: Bool {
        userId == userSession.userId
    }
    
    private func setupNotificationObservers() {
        // User profile updated observer
        NotificationCenter.default.publisher(for: .userProfileUpdated)
            .compactMap { $0.object as? UserProfile }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedProfile in
                self?.handleUserProfileUpdated(updatedProfile)
            }
            .store(in: &cancellables)
    }
    
    private func handleUserProfileUpdated(_ updatedProfile: UserProfile) {
        // Only update if the profile matches our userId
        if updatedProfile.userSummary.id == self.userId {
            self.userProfile = updatedProfile
        }
    }
    
    func loadData() async {
        do {
            if self.isCurrentUser {
                self.userProfile = try await userService.getCurrentUserProfile()
                
                let matchupsResponse = try await matchupService.getMyMatchups(filter: .ACTIVE)
                self.activeMatchups = matchupsResponse.matchups
            } else {
                self.userProfile = try await userService.getUserProfile(userId: self.userId)
                
                // For other users, we might have a different endpoint to get their matchups
                // or we might not show them at all depending on app requirements
                self.activeMatchups = []
            }
        } catch {
            self.errorMessage = "Failed to load profile: \(error.localizedDescription)"
        }
    }
    
    func saveProfileImage(_ image: UIImage) {
        guard self.isCurrentUser else { return }
        
        isImageLoading = true
        
        Task {
            do {
                let userProfile = try await userService.saveCurrentUserAccount(nil, image)
                await MainActor.run {
                    self.userProfile = userProfile
                    isImageLoading = false
                }
            } catch {
                await MainActor.run {
                    isImageLoading = false
                    errorMessage = "Failed to save image: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func selectMatchup(_ matchup: Matchup) {
        selectedMatchup = matchup
    }
}
