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
    
    // Data tracking properties
    private var dataLoadedTime: Date?
    private var dataRequestedTime: Date?
    
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
            await loadData()
        }
    }
    
    func loadData() async {
        do {
            if self.isCurrentUser {
                self.userProfile = try await userService.getCurrentUserProfile()
            } else {
                self.userProfile = try await userService.getUserProfile(userId: self.userId)
            }
            
            let matchupsResponse = try await matchupService.getUserMatchups(userId: self.userId, filter: .ACTIVE)
            self.activeMatchups = matchupsResponse.matchups
            
            // Update the time when data was successfully loaded
            self.dataLoadedTime = Date()
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
