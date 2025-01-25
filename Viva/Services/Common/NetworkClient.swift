import Foundation

final class NetworkClient {
    private let defaultGetHeaders: [String: String] = [:]

    private let defaultPostHeaders = [
        "Content-Type": "application/json",
    ]

    private let settings: NetworkClientSettings

    init(settings: NetworkClientSettings) {
        self.settings = settings
    }

    public func buildPostRequest(
        path: String, body: [String: Any]? = nil,
        headers: [String: String]? = nil
    ) throws
        -> URLRequest
    {
        guard let url = URL(string: settings.baseUrl + path) else {
            throw NetworkClientError(code: "INVALID_URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try getBodyData(body)
        request.allHTTPHeaderFields = defaultPostHeaders
            .merging(settings.headers) { _, new in new }
            .merging(headers ?? [:]) { _, new in new }

        
        return request
    }

    private func getBodyData(_ body: [String: Any]? = nil) throws -> Data? {
        guard let body = body else { return nil }

        do {
            return try JSONSerialization.data(withJSONObject: body)
        } catch {
            throw NetworkClientError(code: "REQUEST_BODY_SERIALIZATION_ERROR")
        }
    }

    public func buildGetRequest(path: String, headers: [String: String]? = nil)
        throws
        -> URLRequest
    {
        guard let url = URL(string: settings.baseUrl + path) else {
            throw NetworkClientError(code: "INVALID_URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = defaultGetHeaders
            .merging(settings.headers) { _, new in new }
            .merging(headers ?? [:]) { _, new in new }

        return request
    }

    public func fetchData(request: URLRequest) async throws -> (
        Data, URLResponse
    ) {
        do {
            return try await URLSession.shared.data(for: request)
        } catch {
            throw NetworkClientError(code: "DATA_FETCH_ERROR")
        }
    }

    public func fetchData<T: Decodable, E: Decodable & Error>(
        request: URLRequest, type: T.Type,
        errorType: E.Type = ErrorResponse.self
    ) async throws -> T {
        let (data, response) = try await self.fetchData(request: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkClientError(code: "INVALID_RESPONSE")
        }

        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(type, from: data)
        case 400...599:
            throw try getErrorResponse(
                httpResponse: httpResponse, data: data, errorType: errorType)
        default:
            throw NetworkClientError(
                code: "INVALID_RESPONSE",
                message: "Unexpected status code: \(httpResponse.statusCode)")
        }
    }

    private func getErrorResponse<E: Decodable & Error>(
        httpResponse: HTTPURLResponse, data: Data, errorType: E.Type
    )
        throws -> E
    {
        do {
            return try JSONDecoder().decode(errorType, from: data)
        } catch {
            let dataString =
                String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NetworkClientError(
                code: "RESPONSE_DECODING_ERROR",
                message: "\(httpResponse.statusCode): \(dataString)")
        }
    }
}
