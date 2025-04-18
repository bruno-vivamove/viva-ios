import Foundation
import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var isImageLoading = false
    @Published var errorMessage: String?
    @Published var userProfile: UserProfile?
    @Published var activeMatchups: [Matchup] = []
    @Published var selectedMatchup: Matchup?
    
    private let userSession: UserSession
    private let userService: UserService
    private let userProfileService: UserProfileService
    private let matchupService: MatchupService
    
    init(userSession: UserSession, userService: UserService, userProfileService: UserProfileService, matchupService: MatchupService) {
        self.userSession = userSession
        self.userService = userService
        self.userProfileService = userProfileService
        self.matchupService = matchupService
        
        // TODO listen for user update events to update the user profile
    }
    
    func loadData() async {
        do {
            self.userProfile = try await userProfileService.getCurrentUserProfile()
            
            let matchupsResponse = try await matchupService.getMyMatchups(filter: .ACTIVE)
            self.activeMatchups = matchupsResponse.matchups
        } catch {
            self.errorMessage = "Failed to load matchups: \(error.localizedDescription)"
        }
    }
    
    func saveProfileImage(_ image: UIImage) {
        isImageLoading = true
        
        Task {
            do {
                let _ = try await userService.saveCurrentUserProfile(nil, image)
                await MainActor.run {
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
