import Alamofire
import Foundation

// MARK: - NetworkClientProtocol

protocol NetworkClientProtocol {
    func get<T: Decodable>(
        path: String,
        queryParams: [String: Any]?,
        headers: [String: String]?
    ) async throws -> T
    
    func post<T: Decodable, E: Encodable>(
        path: String,
        headers: [String: String]?,
        queryParams: [String: Any]?,
        body: E
    ) async throws -> T
    
    func post<T: Decodable>(
        path: String,
        queryParams: [String: Any]?,
        headers: [String: String]?
    ) async throws -> T
    
    func put<T: Decodable>(
        path: String,
        headers: [String: String]?
    ) async throws -> T
    
    func put<T: Decodable, E: Encodable>(
        path: String,
        body: E,
        headers: [String: String]?
    ) async throws -> T
    
    // Methods without response
    func post(
        path: String,
        headers: [String: String]?
    ) async throws
    
    func post<E: Encodable>(
        path: String,
        body: E,
        headers: [String: String]?
    ) async throws
    
    func put(
        path: String,
        headers: [String: String]?
    ) async throws
    
    func put<E: Encodable>(
        path: String,
        body: E,
        headers: [String: String]?
    ) async throws
    
    func patch(
        path: String,
        headers: [String: String]?
    ) async throws
    
    func patch<E: Encodable>(
        path: String,
        body: E,
        headers: [String: String]?
    ) async throws
    
    func delete(
        path: String,
        headers: [String: String]?
    ) async throws
    
    // Upload methods
    func upload<T: Decodable>(
        path: String,
        headers: [String: String]?,
        data: [MultipartData]
    ) async throws -> T
    
    func upload(
        path: String,
        headers: [String: String]?,
        data: [MultipartData]
    ) async throws
    
    // New property for token refresh handling
    var tokenRefreshHandler: TokenRefreshHandler? { get set }
}

// MARK: - Refactored NetworkClient

final class NetworkClient<ErrorType: Decodable & Error>: NetworkClientProtocol, @unchecked Sendable {
    private let session: Session
    private let decoder: JSONDecoder
    private let requestBuilder: RequestBuilder
    private let responseHandler: ResponseHandler<ErrorType>
    let settings: NetworkClientSettings
    
    // Add tokenRefreshHandler property
    var tokenRefreshHandler: TokenRefreshHandler?
    
    init(
        settings: NetworkClientSettings,
        session: Session = .default,
        decoder: JSONDecoder = JSONDecoder.vivaDecoder,
        tokenRefreshHandler: TokenRefreshHandler? = nil
    ) {
        self.settings = settings
        self.session = session
        self.decoder = decoder
        self.requestBuilder = RequestBuilder(settings: settings)
        self.responseHandler = ResponseHandler<ErrorType>(decoder: decoder)
        self.tokenRefreshHandler = tokenRefreshHandler
        
        NetworkLogger.log(message: "NetworkClient initialized with baseURL: \(settings.baseUrl)", level: .info)
    }
    
    // MARK: - Public Request Methods with Response
    
    public func get<T: Decodable>(
        path: String,
        queryParams: [String: Any]? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        NetworkLogger.log(message: "GET Request initiated for path: \(path)", level: .info)
        let url = try requestBuilder.buildURL(path: path, queryParams: queryParams)
        return try await performRequestWithResponse(
            url: url,
            method: .get,
            headers: requestBuilder.buildHeaders(for: .get, additionalHeaders: headers)
        )
    }
    
    public func post<T: Decodable, E: Encodable>(
        path: String,
        headers: [String: String]? = nil,
        queryParams: [String: Any]? = nil,
        body: E
    ) async throws -> T {
        NetworkLogger.log(message: "POST Request initiated for path: \(path)", level: .info)
        let url = try requestBuilder.buildURL(path: path, queryParams: queryParams)
        return try await performRequestWithResponse(
            url: url,
            method: .post,
            headers: requestBuilder.buildHeaders(for: .post, additionalHeaders: headers),
            body: body
        )
    }
    
    public func post<T: Decodable>(
        path: String,
        queryParams: [String: Any]? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        NetworkLogger.log(message: "POST Request initiated for path: \(path)", level: .info)
        let url = try requestBuilder.buildURL(path: path, queryParams: queryParams)
        return try await performRequestWithResponse(
            url: url,
            method: .post,
            headers: requestBuilder.buildHeaders(for: .post, additionalHeaders: headers)
        )
    }
    
    public func put<T: Decodable>(
        path: String,
        headers: [String: String]? = nil
    ) async throws -> T {
        NetworkLogger.log(message: "PUT Request with response initiated for path: \(path)", level: .info)
        let url = try requestBuilder.buildURL(path: path)
        return try await performRequestWithResponse(
            url: url,
            method: .put,
            headers: requestBuilder.buildHeaders(for: .put, additionalHeaders: headers)
        )
    }
    
    public func put<T: Decodable, E: Encodable>(
        path: String,
        body: E,
        headers: [String: String]? = nil
    ) async throws -> T {
        NetworkLogger.log(message: "PUT Request with body and response initiated for path: \(path)", level: .info)
        let url = try requestBuilder.buildURL(path: path)
        return try await performRequestWithResponse(
            url: url,
            method: .put,
            headers: requestBuilder.buildHeaders(for: .put, additionalHeaders: headers),
            body: body
        )
    }
    
    // MARK: - Public Request Methods without Response
    
    public func post(
        path: String,
        headers: [String: String]? = nil
    ) async throws {
        NetworkLogger.log(message: "POST Request (no response) initiated for path: \(path)", level: .info)
        let url = try requestBuilder.buildURL(path: path)
        try await performRequestWithoutResponse(
            url: url,
            method: .post,
            headers: requestBuilder.buildHeaders(for: .post, additionalHeaders: headers)
        )
    }
    
    public func post<E: Encodable>(
        path: String,
        body: E,
        headers: [String: String]? = nil
    ) async throws {
        NetworkLogger.log(message: "POST Request (no response) with body initiated for path: \(path)", level: .info)
        let url = try requestBuilder.buildURL(path: path)
        try await performRequestWithoutResponse(
            url: url,
            method: .post,
            body: body,
            headers: requestBuilder.buildHeaders(for: .post, additionalHeaders: headers)
        )
    }
    
    public func put(
        path: String,
        headers: [String: String]? = nil
    ) async throws {
        NetworkLogger.log(message: "PUT Request initiated for path: \(path)", level: .info)
        let url = try requestBuilder.buildURL(path: path)
        try await performRequestWithoutResponse(
            url: url,
            method: .put,
            headers: requestBuilder.buildHeaders(for: .put, additionalHeaders: headers)
        )
    }
    
    public func put<E: Encodable>(
        path: String,
        body: E,
        headers: [String: String]? = nil
    ) async throws {
        NetworkLogger.log(message: "PUT Request with body initiated for path: \(path)", level: .info)
        let url = try requestBuilder.buildURL(path: path)
        try await performRequestWithoutResponse(
            url: url,
            method: .put,
            body: body,
            headers: requestBuilder.buildHeaders(for: .put, additionalHeaders: headers)
        )
    }
    
    public func patch(
        path: String,
        headers: [String: String]? = nil
    ) async throws {
        NetworkLogger.log(message: "PATCH Request initiated for path: \(path)", level: .info)
        let url = try requestBuilder.buildURL(path: path)
        try await performRequestWithoutResponse(
            url: url,
            method: .patch,
            headers: requestBuilder.buildHeaders(for: .patch, additionalHeaders: headers)
        )
    }
    
    public func patch<E: Encodable>(
        path: String,
        body: E,
        headers: [String: String]? = nil
    ) async throws {
        NetworkLogger.log(message: "PATCH Request with body initiated for path: \(path)", level: .info)
        let url = try requestBuilder.buildURL(path: path)
        try await performRequestWithoutResponse(
            url: url,
            method: .patch,
            body: body,
            headers: requestBuilder.buildHeaders(for: .patch, additionalHeaders: headers)
        )
    }
    
    public func delete(
        path: String,
        headers: [String: String]? = nil
    ) async throws {
        NetworkLogger.log(message: "DELETE Request initiated for path: \(path)", level: .info)
        let url = try requestBuilder.buildURL(path: path)
        try await performRequestWithoutResponse(
            url: url,
            method: .delete,
            headers: requestBuilder.buildHeaders(for: .delete, additionalHeaders: headers)
        )
    }
    
    // MARK: - Upload Methods
    
    public func upload<T: Decodable>(
        path: String,
        headers: [String: String]? = nil,
        data: [MultipartData]
    ) async throws -> T {
        NetworkLogger.log(message: "Upload Request initiated for path: \(path)", level: .info)
        let url = try requestBuilder.buildURL(path: path)
        let requestHeaders = requestBuilder.buildHeaders(for: .upload, additionalHeaders: headers)
        
        NetworkLogger.log(message: "Upload Request: \(url.absoluteString)", level: .debug)
        NetworkLogger.log(message: "Headers: \(requestHeaders.filter { $0.name != "Authorization" })", level: .debug)
        NetworkLogger.log(message: "Uploading \(data.count) files", level: .debug)
        
        return try await withCheckedThrowingContinuation { continuation in
            session.upload(
                multipartFormData: { multipartFormData in
                    self.configureMultipartFormData(multipartFormData, with: data)
                },
                to: url,
                method: .patch,
                headers: requestHeaders
            )
            .uploadProgress { progress in
                NetworkLogger.log(
                    message: "Upload progress: \(progress.fractionCompleted * 100)% (\(progress.completedUnitCount)/\(progress.totalUnitCount) bytes)",
                    level: .debug
                )
            }
            .validate()
            .responseDecodable(of: T.self, decoder: decoder) { [weak self] response in
                guard let self = self else { return }
                
                self.responseHandler.logResponse(response)
                
                switch response.result {
                case .success(let value):
                    NetworkLogger.log(message: "Upload completed successfully", level: .info)
                    continuation.resume(returning: value)
                case .failure(let error):
                    // Create retry handler closure for uploads
                    let retryHandler = { [weak self] () async throws -> T in
                        guard let self = self else {
                            throw NetworkClientError(code: "INTERNAL_ERROR", message: "NetworkClient was deallocated")
                        }
                        // Retry the upload with potentially new token
                        let updatedHeaders = self.requestBuilder.buildHeaders(for: .upload, additionalHeaders: headers)
                        return try await self.upload(path: path, headers: updatedHeaders.dictionary, data: data)
                    }
                    
                    self.responseHandler.handleError(
                        error,
                        response: response,
                        continuation: continuation,
                        tokenRefreshHandler: self.tokenRefreshHandler,
                        retryHandler: retryHandler
                    )
                }
            }
        }
    }
    
    public func upload(
        path: String,
        headers: [String: String]? = nil,
        data: [MultipartData]
    ) async throws {
        NetworkLogger.log(message: "Upload Request (no response) initiated for path: \(path)", level: .info)
        let url = try requestBuilder.buildURL(path: path)
        let requestHeaders = requestBuilder.buildHeaders(for: .upload, additionalHeaders: headers)
        
        NetworkLogger.log(message: "Upload Request: \(url.absoluteString)", level: .debug)
        NetworkLogger.log(message: "Headers: \(requestHeaders.filter { $0.name != "Authorization" })", level: .debug)
        NetworkLogger.log(message: "Uploading \(data.count) files", level: .debug)
        
        try await withCheckedThrowingContinuation { continuation in
            session.upload(
                multipartFormData: { multipartFormData in
                    self.configureMultipartFormData(multipartFormData, with: data)
                },
                to: url,
                method: .patch,
                headers: requestHeaders
            )
            .uploadProgress { progress in
                NetworkLogger.log(
                    message: "Upload progress: \(progress.fractionCompleted * 100)% (\(progress.completedUnitCount)/\(progress.totalUnitCount) bytes)",
                    level: .debug
                )
            }
            .validate()
            .response { [weak self] response in
                guard let self = self else { return }
                
                self.responseHandler.logResponse(response)
                
                switch response.result {
                case .success:
                    NetworkLogger.log(message: "Upload completed successfully", level: .info)
                    continuation.resume()
                case .failure(let error):
                    // Create retry handler closure for uploads without response
                    let retryHandler = { [weak self] () async throws in
                        guard let self = self else {
                            throw NetworkClientError(code: "INTERNAL_ERROR", message: "NetworkClient was deallocated")
                        }
                        // Retry the upload with potentially new token
                        try await self.upload(path: path, headers: nil, data: data)
                    }
                    
                    self.responseHandler.handleErrorWithoutResponse(
                        error,
                        response: response,
                        continuation: continuation,
                        tokenRefreshHandler: self.tokenRefreshHandler,
                        retryHandler: retryHandler
                    )
                }
            }
        }
    }
    
    // MARK: - Private Request Methods
    
    private func performRequestWithResponse<T: Decodable>(
        url: URL,
        method: HTTPMethod,
        headers: HTTPHeaders
    ) async throws -> T {
        NetworkLogger.log(message: "\(method.rawValue) Request: \(url.absoluteString)", level: .debug)
        NetworkLogger.log(message: "Headers: \(headers.filter { $0.name != "Authorization" })", level: .debug)
        
        return try await withCheckedThrowingContinuation { continuation in
            session.request(url, method: method, headers: headers)
                .validate()
                .responseDecodable(of: T.self, decoder: decoder) { [weak self] response in
                    guard let self = self else { return }
                    
                    self.responseHandler.logResponse(response)
                    
                    switch response.result {
                    case .success(let value):
                        NetworkLogger.log(message: "Request completed successfully", level: .info)
                        continuation.resume(returning: value)
                    case .failure(let error):
                        // Create retry handler closure
                        let retryHandler = { [weak self] () async throws -> T in
                            guard let self = self else {
                                throw NetworkClientError(code: "INTERNAL_ERROR", message: "NetworkClient was deallocated")
                            }
                            // Recreate request with potentially new token
                            let updatedHeaders = self.requestBuilder.buildHeaders(for: method.toRequestType(), additionalHeaders: nil)
                            return try await self.performRequestWithResponse(url: url, method: method, headers: updatedHeaders)
                        }
                        
                        self.responseHandler.handleError(
                            error,
                            response: response,
                            continuation: continuation,
                            tokenRefreshHandler: self.tokenRefreshHandler,
                            retryHandler: retryHandler
                        )
                    }
                }
        }
    }
    
    private func performRequestWithResponse<T: Decodable, E: Encodable>(
        url: URL,
        method: HTTPMethod,
        headers: HTTPHeaders,
        body: E
    ) async throws -> T {
        NetworkLogger.log(message: "\(method.rawValue) Request: \(url.absoluteString)", level: .debug)
        NetworkLogger.log(message: "Headers: \(headers.filter { $0.name != "Authorization" })", level: .debug)
        NetworkLogger.log(message: "Body: \(body)", level: .debug)
        
        return try await withCheckedThrowingContinuation { continuation in
            session.request(
                url,
                method: method,
                parameters: body,
                encoder: JSONParameterEncoder.default,
                headers: headers
            )
            .validate()
            .responseDecodable(of: T.self, decoder: decoder) { [weak self] response in
                guard let self = self else { return }
                
                self.responseHandler.logResponse(response)
                
                switch response.result {
                case .success(let value):
                    NetworkLogger.log(message: "Request completed successfully", level: .info)
                    continuation.resume(returning: value)
                case .failure(let error):
                    // Create retry handler closure
                    let retryHandler = { [weak self] () async throws -> T in
                        guard let self = self else {
                            throw NetworkClientError(code: "INTERNAL_ERROR", message: "NetworkClient was deallocated")
                        }
                        // Recreate request with potentially new token
                        let updatedHeaders = self.requestBuilder.buildHeaders(for: method.toRequestType(), additionalHeaders: nil)
                        return try await self.performRequestWithResponse(url: url, method: method, headers: updatedHeaders, body: body)
                    }
                    
                    self.responseHandler.handleError(
                        error,
                        response: response,
                        continuation: continuation,
                        tokenRefreshHandler: self.tokenRefreshHandler,
                        retryHandler: retryHandler
                    )
                }
            }
        }
    }
    
    private func performRequestWithoutResponse(
        url: URL,
        method: HTTPMethod,
        headers: HTTPHeaders
    ) async throws {
        NetworkLogger.log(message: "\(method.rawValue) Request: \(url.absoluteString)", level: .debug)
        NetworkLogger.log(message: "Headers: \(headers.filter { $0.name != "Authorization" })", level: .debug)
        
        try await withCheckedThrowingContinuation { continuation in
            session.request(url, method: method, headers: headers)
                .validate()
                .response { [weak self] response in
                    guard let self = self else { return }
                    
                    self.responseHandler.logResponse(response)
                    
                    switch response.result {
                    case .success:
                        NetworkLogger.log(message: "Request completed successfully", level: .info)
                        continuation.resume()
                    case .failure(let error):
                        // Create retry handler closure
                        let retryHandler = { [weak self] () async throws -> Void in
                            guard let self = self else {
                                throw NetworkClientError(code: "INTERNAL_ERROR", message: "NetworkClient was deallocated")
                            }
                            // Recreate request with potentially new token
                            let updatedHeaders = self.requestBuilder.buildHeaders(for: method.toRequestType(), additionalHeaders: nil)
                            try await self.performRequestWithoutResponse(url: url, method: method, headers: updatedHeaders)
                        }
                        
                        self.responseHandler.handleErrorWithoutResponse(
                            error,
                            response: response,
                            continuation: continuation,
                            tokenRefreshHandler: self.tokenRefreshHandler,
                            retryHandler: retryHandler
                        )
                    }
                }
        }
    }
    
    private func performRequestWithoutResponse<E: Encodable>(
        url: URL,
        method: HTTPMethod,
        body: E,
        headers: HTTPHeaders
    ) async throws {
        NetworkLogger.log(message: "\(method.rawValue) Request: \(url.absoluteString)", level: .debug)
        NetworkLogger.log(message: "Headers: \(headers.filter { $0.name != "Authorization" })", level: .debug)
        NetworkLogger.log(message: "Body: \(body)", level: .debug)
        
        try await withCheckedThrowingContinuation { continuation in
            session.request(
                url,
                method: method,
                parameters: body,
                encoder: JSONParameterEncoder.default,
                headers: headers
            )
            .validate()
            .response { [weak self] response in
                guard let self = self else { return }
                
                self.responseHandler.logResponse(response)
                
                switch response.result {
                case .success:
                    NetworkLogger.log(message: "Request completed successfully", level: .info)
                    continuation.resume()
                case .failure(let error):
                    // Create retry handler closure
                    let retryHandler = { [weak self] () async throws -> Void in
                        guard let self = self else {
                            throw NetworkClientError(code: "INTERNAL_ERROR", message: "NetworkClient was deallocated")
                        }
                        // Recreate request with potentially new token
                        let updatedHeaders = self.requestBuilder.buildHeaders(for: method.toRequestType(), additionalHeaders: nil)
                        try await self.performRequestWithoutResponse(url: url, method: method, body: body, headers: updatedHeaders)
                    }
                    
                    self.responseHandler.handleErrorWithoutResponse(
                        error,
                        response: response,
                        continuation: continuation,
                        tokenRefreshHandler: self.tokenRefreshHandler,
                        retryHandler: retryHandler
                    )
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func configureMultipartFormData(_ multipartFormData: MultipartFormData, with data: [MultipartData]) {
        data.forEach { dataItem in
            NetworkLogger.log(message: "Appending file: \(dataItem.name)", level: .debug)
            multipartFormData.append(
                dataItem.data,
                withName: dataItem.name,
                fileName: dataItem.fileName,
                mimeType: dataItem.mimeType
            )
        }
        NetworkLogger.log(message: "Total upload size: \(multipartFormData.contentLength) bytes", level: .debug)
    }
}

// MARK: - HTTPMethod Extension

extension HTTPMethod {
    func toRequestType() -> RequestBuilder.RequestType {
        switch self {
        case .get:
            return .get
        case .post:
            return .post
        case .put:
            return .put
        case .patch:
            return .patch
        case .delete:
            return .delete
        default:
            return .get // Default case
        }
    }
}

// MARK: - Custom JSON Decoder Extension

extension JSONDecoder {
    static let vivaDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXX"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        decoder.dateDecodingStrategy = .formatted(formatter)
        return decoder
    }()
}
