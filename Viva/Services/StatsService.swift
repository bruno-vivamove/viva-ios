import Foundation

final class StatsService: ObservableObject {
    private let networkClient: NetworkClient<VivaErrorResponse>
    
    init(networkClient: NetworkClient<VivaErrorResponse>) {
        self.networkClient = networkClient
    }
    
    func getUserMatchupStats() async throws -> UserMatchupStatsResponse {
        return try await networkClient.get(
            path: "/stats/matchups"
        )
    }
}
