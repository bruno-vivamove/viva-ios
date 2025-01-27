import Foundation

final class NetworkClient {
    private let defaultGetHeaders: [String: String] = [:]
    
    private let defaultPostHeaders = [
        "Content-Type": "application/json"
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
            throw NetworkClientError(
                code: "INVALID_URL", message: "Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try getBodyData(body)
        request.allHTTPHeaderFields =
        defaultPostHeaders
            .merging(settings.headers) { _, new in new }
            .merging(headers ?? [:]) { _, new in new }
        
        return request
    }
    
    public func buildPutRequest(
        path: String, body: Any? = nil,
        headers: [String: String]? = nil
    ) throws
    -> URLRequest
    {
        guard let url = URL(string: settings.baseUrl + path) else {
            throw NetworkClientError(
                code: "INVALID_URL", message: "Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = try getBodyData(body)
        request.allHTTPHeaderFields =
        defaultPostHeaders
            .merging(settings.headers) { _, new in new }
            .merging(headers ?? [:]) { _, new in new }
        
        return request
    }
    
    private func getBodyData(_ body: Any? = nil) throws -> Data? {
        guard let body = body else { return nil }
        
        do {
            if let encodable = body as? Encodable {
                let encoder = JSONEncoder()
                return try encoder.encode(encodable)
            } else {
                return try JSONSerialization.data(withJSONObject: body)
            }
        } catch {
            throw NetworkClientError(
                code: "REQUEST_BODY_SERIALIZATION_ERROR",
                message: error.localizedDescription)
        }
    }
    
    public func buildGetRequest(path: String, headers: [String: String]? = nil)
    throws
    -> URLRequest
    {
        guard let url = URL(string: settings.baseUrl + path) else {
            throw NetworkClientError(
                code: "INVALID_URL", message: "Unable to create URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields =
        defaultGetHeaders
            .merging(settings.headers) { _, new in new }
            .merging(headers ?? [:]) { _, new in new }
        
        return request
    }
    
    public func fetchData(request: URLRequest) async throws -> (
        Data, URLResponse
    ) {
        debugRequest(request)
        
        do {
            return try await URLSession.shared.data(for: request)
        } catch {
            throw NetworkClientError(
                code: "DATA_FETCH_ERROR", message: "Data fetch error")
        }
    }
    
    public func fetchData<T: Decodable, E: Decodable & Error>(
        request: URLRequest, type: T.Type,
        errorType: E.Type = ErrorResponse.self
    ) async throws -> T {
        let (data, response) = try await self.fetchData(request: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkClientError(
                code: "INVALID_RESPONSE", message: "Invalid response")
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try JSONDecoder().decode(type, from: data)
            } catch {
                let message =
                "Error parsing response: "
                + (String(data: data, encoding: .utf8) ?? "<nil>")
                
                throw NetworkClientError(
                    code: "ERROR_PARSING_RESPONSE",
                    message: message)
            }
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

    func debugRequest(_ request: URLRequest) {
        print("🌐 URL: \(request.url?.absoluteString ?? "nil")")
        print("📍 Method: \(request.httpMethod ?? "nil")")
        print("📋 Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        if let body = request.httpBody {
            if let bodyString = String(data: body, encoding: .utf8) {
                print("📦 Body: \(bodyString)")
            } else {
                print("📦 Body: \(body) (not UTF-8)")
            }
        }
        
        print("⏰ Timeout: \(request.timeoutInterval)")
        print("🔒 Cache Policy: \(request.cachePolicy)")
    }
}
