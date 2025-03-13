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
            NetworkLogger.log(message: "Failed to create URL components with base: \(settings.baseUrl) and path: \(path)", level: .error)
            throw NetworkClientError(code: "INVALID_URL", message: "Invalid URL")
        }
        
        if let queryParams = queryParams {
            components.queryItems = queryParams.map { key, value in
                URLQueryItem(name: key, value: String(describing: value))
            }
        }
        
        guard let url = components.url else {
            NetworkLogger.log(message: "Failed to create URL from components", level: .error)
            throw NetworkClientError(code: "INVALID_URL", message: "Invalid URL")
        }
        
        NetworkLogger.log(message: "Built URL: \(url.absoluteString)", level: .debug)
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
        
        let headers = defaultHeaders
            .merging(settings.headers) { _, new in new }
            .merging(additionalHeaders ?? [:]) { _, new in new }
        
        NetworkLogger.log(message: "Built headers: \(headers.filter { $0.key != "Authorization" })", level: .debug)
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
