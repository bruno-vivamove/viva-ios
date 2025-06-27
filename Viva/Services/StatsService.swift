import Foundation

final class StatsService: ObservableObject {
    private let networkClient: NetworkClient<VivaErrorResponse>
    
    init(networkClient: NetworkClient<VivaErrorResponse>) {
        self.networkClient = networkClient
    }
    
    func getUserMatchupStats() async throws -> UserSeriesStatsListResponse {
        return try await networkClient.get(
            path: "/stats/v2/matchups"
        )
    }
}
