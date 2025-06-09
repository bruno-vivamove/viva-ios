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
    ///   - isBackgroundUpdate: Whether this upload is from a background task
    /// - Returns: Updated matchup details
    func saveUserMeasurements(
        matchupId: String, 
        measurements: [MatchupUserMeasurement],
        isBackgroundUpdate: Bool = false
    ) async throws -> MatchupDetails {
        let request = MatchupUserMeasurements(
            matchupUserMeasurements: measurements,
            isBackgroundUpdate: isBackgroundUpdate
        )
        
        let matchupDetails: MatchupDetails = try await networkClient.put(
            path: "/matchups/\(matchupId)/user-measurements",
            body: request
        )
        
        NotificationCenter.default.post(
            name: .matchupUpdated,
            object: matchupDetails
        )
        
        return matchupDetails
    }
} 