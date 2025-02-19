import SwiftUI

@MainActor
class MatchupCreationCoordinator: ObservableObject {
    let matchupService: MatchupService
    let friendService: FriendService
    let userSession: UserSession
    @Published var isCreatingMatchup = false
    @Published var error: Error?
    
    init(matchupService: MatchupService, friendService: FriendService, userSession: UserSession) {
        self.matchupService = matchupService
        self.friendService = friendService
        self.userSession = userSession
    }
    
    func createMatchup(selectedCategories: [MatchupCategory], usersPerSide: Int) async -> MatchupDetails? {
        isCreatingMatchup = true
        defer { isCreatingMatchup = false }
        
        let measurementTypes = selectedCategories
            .filter { $0.isSelected }
            .compactMap { categoryToMeasurementType($0.id) }
        
        let request = MatchupRequest(
            displayName: "New Challenge",
            usersPerSide: usersPerSide,
            measurementTypes: measurementTypes
        )
        
        do {
            return try await matchupService.createMatchup(request)
        } catch {
            self.error = error
            return nil
        }
    }
    
    private func categoryToMeasurementType(_ categoryId: String) -> MeasurementType {
        switch categoryId {
        case "calories":
            return .energyBurned  // Will be serialized as "ENERGY_BURNED"
        case "steps":
            return .steps         // Will be serialized as "STEPS"
        case "ehr":
            return .elevatedHeartRate  // Will be serialized as "ELEVATED_HEART_RATE"
        case "strength":
            return .strengthTraining   // Will be serialized as "STRENGTH_TRAINING"
        case "sleep":
            return .asleep      // Will be serialized as "ASLEEP"
        default:
            return .steps       // Default fallback
        }
    }
}
