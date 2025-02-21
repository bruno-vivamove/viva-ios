import Foundation

final class HealthService {
    private let networkClient: NetworkClient

    struct PingResponse: Encodable, Decodable {
        let response: String
    }

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    func ping() async throws -> String {
        let response: PingResponse = try await networkClient.get(
            path: "/viva/health/ping"
        )
        return response.response
    }
}
