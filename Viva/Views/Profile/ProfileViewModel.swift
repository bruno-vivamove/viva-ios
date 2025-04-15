import Foundation
import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var isImageLoading = false
    @Published var errorMessage: String?
    @Published var activeMatchups: [Matchup] = []
    @Published var selectedMatchup: Matchup?
    
    private let userSession: UserSession
    private let userProfileService: UserProfileService
    private let matchupService: MatchupService
    
    init(userSession: UserSession, userProfileService: UserProfileService, matchupService: MatchupService) {
        self.userSession = userSession
        self.userProfileService = userProfileService
        self.matchupService = matchupService
    }
    
    func loadActiveMatchups() async {
        do {
            let response = try await matchupService.getMyMatchups(filter: .ACTIVE)
            self.activeMatchups = response.matchups
        } catch {
            self.errorMessage = "Failed to load matchups: \(error.localizedDescription)"
        }
    }
    
    func saveProfileImage(_ image: UIImage) {
        isImageLoading = true
        
        Task {
            do {
                let _ = try await userProfileService.saveCurrentUserProfile(nil, image)
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
