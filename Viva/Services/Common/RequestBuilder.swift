import Alamofire
import Foundation

final class RequestBuilder {
    private let settings: NetworkClientSettings
    
    private let defaultGetHeaders: [String: String] = [:]
    private let defaultPostHeaders = [
        "Content-Type": "application/json"
    ]
    private let defaultUploadHeaders: [String: String] = [:]
    private let defaultDeleteHeaders: [String: String] = [:]
    
    init(settings: NetworkClientSettings) {
        self.settings = settings
    }
    
    func buildURL(path: String, queryParams: [String: Any]? = nil) throws -> URL {
        guard var components = URLComponents(string: settings.baseUrl + path) else {
            AppLogger.error("Failed to create URL components with base: \(settings.baseUrl) and path: \(path)", category: .network)
            throw NetworkClientError(code: "INVALID_URL", message: "Invalid URL")
        }
        
        if let queryParams = queryParams {
            components.queryItems = queryParams.map { key, value in
                URLQueryItem(name: key, value: String(describing: value))
            }
        }
        
        guard let url = components.url else {
            AppLogger.error("Failed to create URL from components", category: .network)
            throw NetworkClientError(code: "INVALID_URL", message: "Invalid URL")
        }
        
        return url
    }
    
    func buildHeaders(
        for requestType: RequestType,
        additionalHeaders: [String: String]? = nil
    ) -> HTTPHeaders {
        let defaultHeaders: [String: String]
        
        switch requestType {
        case .get:
            defaultHeaders = defaultGetHeaders
        case .post, .put, .patch:
            defaultHeaders = defaultPostHeaders
        case .upload:
            defaultHeaders = defaultUploadHeaders
        case .delete:
            defaultHeaders = defaultDeleteHeaders
        }
        
        var headers = defaultHeaders
            .merging(settings.headers) { _, new in new }
            .merging(additionalHeaders ?? [:]) { _, new in new }
        
        if headers["X-Request-ID"] == nil {
            headers["X-Request-ID"] = UUID().uuidString
        }
        
        return HTTPHeaders(headers)
    }
    
    enum RequestType {
        case get
        case post
        case put
        case patch
        case upload
        case delete
    }
}
