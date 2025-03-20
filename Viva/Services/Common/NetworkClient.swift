import Alamofire
import Foundation

// MARK: - Refactored NetworkClient

final class NetworkClient<ErrorType: Decodable & Error>: @unchecked Sendable {
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
        self.responseHandler = ResponseHandler<ErrorType>(decoder: decoder, shouldLogBodies: settings.shouldLogBodies)
        self.tokenRefreshHandler = tokenRefreshHandler
        
        AppLogger.info("NetworkClient initialized with baseURL: \(settings.baseUrl)", category: .network)
    }
    
    // MARK: - Public Request Methods with Response
    
    public func get<T: Decodable>(
        path: String,
        queryParams: [String: Any]? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        AppLogger.info("GET Request initiated for path: \(path)", category: .network)
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
        AppLogger.info("POST Request initiated for path: \(path)", category: .network)
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
        AppLogger.info("POST Request initiated for path: \(path)", category: .network)
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
        AppLogger.info("PUT Request with response initiated for path: \(path)", category: .network)
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
        AppLogger.info("PUT Request with body and response initiated for path: \(path)", category: .network)
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
        AppLogger.info("POST Request (no response) initiated for path: \(path)", category: .network)
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
        AppLogger.info("POST Request (no response) with body initiated for path: \(path)", category: .network)
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
        AppLogger.info("PUT Request initiated for path: \(path)", category: .network)
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
        AppLogger.info("PUT Request with body initiated for path: \(path)", category: .network)
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
        AppLogger.info("PATCH Request initiated for path: \(path)", category: .network)
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
        AppLogger.info("PATCH Request with body initiated for path: \(path)", category: .network)
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
        AppLogger.info("DELETE Request initiated for path: \(path)", category: .network)
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
        AppLogger.info("Upload Request initiated for path: \(path)", category: .network)
        let url = try requestBuilder.buildURL(path: path)
        let requestHeaders = requestBuilder.buildHeaders(for: .upload, additionalHeaders: headers)
        
        AppLogger.debug("Upload Request: \(url.absoluteString)", category: .network)
        AppLogger.debug("Headers: \(requestHeaders.filter { $0.name != "Authorization" })", category: .network)
        AppLogger.debug("Uploading \(data.count) files", category: .network)
        
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
                AppLogger.debug(
                    "Upload progress: \(progress.fractionCompleted * 100)% (\(progress.completedUnitCount)/\(progress.totalUnitCount) bytes)",
                    category: .network
                )
            }
            .validate()
            .responseDecodable(of: T.self, decoder: decoder) { [weak self] response in
                guard let self = self else { return }
                
                self.responseHandler.logResponse(response)
                
                switch response.result {
                case .success(let value):
                    AppLogger.info("Upload completed successfully", category: .network)
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
        AppLogger.info("Upload Request (no response) initiated for path: \(path)", category: .network)
        let url = try requestBuilder.buildURL(path: path)
        let requestHeaders = requestBuilder.buildHeaders(for: .upload, additionalHeaders: headers)
        
        AppLogger.debug("Upload Request: \(url.absoluteString)", category: .network)
        AppLogger.debug("Headers: \(requestHeaders.filter { $0.name != "Authorization" })", category: .network)
        AppLogger.debug("Uploading \(data.count) files", category: .network)
        
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
                AppLogger.debug(
                    "Upload progress: \(progress.fractionCompleted * 100)% (\(progress.completedUnitCount)/\(progress.totalUnitCount) bytes)",
                    category: .network
                )
            }
            .validate()
            .response { [weak self] response in
                guard let self = self else { return }
                
                self.responseHandler.logResponse(response)
                
                switch response.result {
                case .success:
                    AppLogger.info("Upload completed successfully", category: .network)
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
        AppLogger.debug("\(method.rawValue) Request: \(url.absoluteString)", category: .network)
        AppLogger.debug("Headers: \(headers.filter { $0.name != "Authorization" })", category: .network)
        
        return try await withCheckedThrowingContinuation { continuation in
            session.request(url, method: method, headers: headers)
                .validate()
                .responseDecodable(of: T.self, decoder: decoder) { [weak self] response in
                    guard let self = self else { return }
                    
                    self.responseHandler.logResponse(response)
                    
                    switch response.result {
                    case .success(let value):
                        AppLogger.info("Request completed successfully", category: .network)
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
        AppLogger.debug("\(method.rawValue) Request: \(url.absoluteString)", category: .network)
        AppLogger.debug("Headers: \(headers.filter { $0.name != "Authorization" })", category: .network)
        
        if settings.shouldLogBodies {
            AppLogger.debug("Body: \(body)", category: .network)
        }
        
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
                    AppLogger.info("Request completed successfully", category: .network)
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
        AppLogger.debug("\(method.rawValue) Request: \(url.absoluteString)", category: .network)
        AppLogger.debug("Headers: \(headers.filter { $0.name != "Authorization" })", category: .network)
        
        try await withCheckedThrowingContinuation { continuation in
            session.request(url, method: method, headers: headers)
                .validate()
                .response { [weak self] response in
                    guard let self = self else { return }
                    
                    self.responseHandler.logResponse(response)
                    
                    switch response.result {
                    case .success:
                        AppLogger.info("Request completed successfully", category: .network)
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
        AppLogger.debug("\(method.rawValue) Request: \(url.absoluteString)", category: .network)
        AppLogger.debug("Headers: \(headers.filter { $0.name != "Authorization" })", category: .network)
        
        if settings.shouldLogBodies {
            AppLogger.debug("Body: \(body)", category: .network)
        }
        
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
                    AppLogger.info("Request completed successfully", category: .network)
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
            AppLogger.debug("Appending file: \(dataItem.name)", category: .network)
            multipartFormData.append(
                dataItem.data,
                withName: dataItem.name,
                fileName: dataItem.fileName,
                mimeType: dataItem.mimeType
            )
        }
        AppLogger.debug("Total upload size: \(multipartFormData.contentLength) bytes", category: .network)
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
