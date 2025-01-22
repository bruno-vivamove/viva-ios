import Foundation

final class NetworkClient {
    private static let defaultBaseUrl = "http://https://viva-svc-7e66d6saga-ue.a.run.app"
    private static let referer = "https://dev.vivamove.io"
    
    private let baseUrl: String
    
    init(baseUrl: String = defaultBaseUrl) {
        self.baseUrl = baseUrl
    }

    public func buildPostRequest(path: String, body: [String: Any]) throws
        -> URLRequest
    {
        guard let url = URL(string: baseUrl + path) else {
            throw ClientError(code: "INVALID_URL")
        }

        guard let httpBody = try? JSONSerialization.data(withJSONObject: body)
        else {
            throw ClientError(code: "REQUEST_BODY_SERIALIZATION_ERROR")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(NetworkClient.referer, forHTTPHeaderField: "Referer")
        request.httpBody = httpBody
        return request
    }

    public func fetchData(request: URLRequest) async throws -> (
        Data, URLResponse
    ) {
        do {
            return try await URLSession.shared.data(for: request)
        } catch {
            throw ClientError(code: "DATA_FETCH_ERROR")
        }
    }

    public func fetchData<T: Decodable, E: Decodable & Error>(
        request: URLRequest, type: T.Type,
        errorType: E.Type = ErrorResponse.self
    ) async throws -> T {
        let (data, response) = try await self.fetchData(request: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClientError(code: "INVALID_RESPONSE")
        }

        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(type, from: data)
        case 400...599:
            throw try getErrorResponse(
                httpResponse: httpResponse, data: data, errorType: errorType)
        default:
            throw ClientError(
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
            throw ClientError(
                code: "RESPONSE_DECODING_ERROR",
                message: "\(httpResponse.statusCode): \(dataString)")
        }
    }
}
