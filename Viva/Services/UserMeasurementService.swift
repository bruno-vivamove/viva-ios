import Foundation

final class UserMeasurementService: ObservableObject {
    private let networkClient: NetworkClient<VivaErrorResponse>
    
    init(networkClient: NetworkClient<VivaErrorResponse>) {
        self.networkClient = networkClient
    }
    
    // MARK: - User Measurements
    
    /// Saves user measurements for a specific matchup
    /// - Parameters:
    ///   - matchupId: The ID of the matchup
    ///   - measurements: Array of measurements to save
    /// - Returns: Updated matchup details
    func saveUserMeasurements(matchupId: String, measurements: [MatchupUserMeasurement]) async throws -> MatchupDetails {
        let request = MatchupUserMeasurements(matchupUserMeasurements: measurements)
        
        let matchupDetails: MatchupDetails = try await networkClient.put(
            path: "/viva/matchups/\(matchupId)/user-measurements",
            body: request
        )
        
        NotificationCenter.default.post(
            name: .matchupUpdated,
            object: matchupDetails
        )
        
        return matchupDetails
    }
} 