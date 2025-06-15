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
        tokenRefreshHandler: TokenRefreshHandler? = nil,
        errorManager: ErrorManager? = nil
    ) {
        self.settings = settings
        self.session = session
        self.decoder = decoder
        self.requestBuilder = RequestBuilder(settings: settings)
        self.responseHandler = ResponseHandler<ErrorType>(
            decoder: decoder,
            shouldLogBodies: settings.shouldLogBodies,
            errorManager: errorManager
        )
        self.tokenRefreshHandler = tokenRefreshHandler

        AppLogger.infoLocal(
            "NetworkClient initialized with baseURL: \(settings.baseUrl)",
            category: .network
        )
    }

    // MARK: - Public Request Methods with Response

    public func get<T: Decodable>(
        path: String,
        queryParams: [String: Any]? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        let url = try requestBuilder.buildURL(
            path: path,
            queryParams: queryParams
        )
        return try await performRequestWithResponse(
            url: url,
            method: .get,
            headers: requestBuilder.buildHeaders(
                for: .get,
                additionalHeaders: headers
            ),
            remainingRetries: settings.maxRetries
        )
    }

    public func post<T: Decodable, E: Encodable>(
        path: String,
        headers: [String: String]? = nil,
        queryParams: [String: Any]? = nil,
        body: E
    ) async throws -> T {
        let url = try requestBuilder.buildURL(
            path: path,
            queryParams: queryParams
        )
        return try await performRequestWithResponse(
            url: url,
            method: .post,
            headers: requestBuilder.buildHeaders(
                for: .post,
                additionalHeaders: headers
            ),
            body: body,
            remainingRetries: settings.maxRetries
        )
    }

    public func post<T: Decodable>(
        path: String,
        queryParams: [String: Any]? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        let url = try requestBuilder.buildURL(
            path: path,
            queryParams: queryParams
        )
        return try await performRequestWithResponse(
            url: url,
            method: .post,
            headers: requestBuilder.buildHeaders(
                for: .post,
                additionalHeaders: headers
            ),
            remainingRetries: settings.maxRetries
        )
    }

    public func put<T: Decodable>(
        path: String,
        headers: [String: String]? = nil
    ) async throws -> T {
        let url = try requestBuilder.buildURL(path: path)
        return try await performRequestWithResponse(
            url: url,
            method: .put,
            headers: requestBuilder.buildHeaders(
                for: .put,
                additionalHeaders: headers
            ),
            remainingRetries: settings.maxRetries
        )
    }

    public func put<T: Decodable, E: Encodable>(
        path: String,
        body: E,
        headers: [String: String]? = nil
    ) async throws -> T {
        let url = try requestBuilder.buildURL(path: path)
        return try await performRequestWithResponse(
            url: url,
            method: .put,
            headers: requestBuilder.buildHeaders(
                for: .put,
                additionalHeaders: headers
            ),
            body: body,
            remainingRetries: settings.maxRetries
        )
    }

    // MARK: - Public Request Methods without Response

    public func post(
        path: String,
        headers: [String: String]? = nil
    ) async throws {
        let url = try requestBuilder.buildURL(path: path)
        try await performRequestWithoutResponse(
            url: url,
            method: .post,
            headers: requestBuilder.buildHeaders(
                for: .post,
                additionalHeaders: headers
            ),
            remainingRetries: settings.maxRetries
        )
    }

    public func post<E: Encodable>(
        path: String,
        body: E,
        headers: [String: String]? = nil
    ) async throws {
        let url = try requestBuilder.buildURL(path: path)
        try await performRequestWithoutResponse(
            url: url,
            method: .post,
            body: body,
            headers: requestBuilder.buildHeaders(
                for: .post,
                additionalHeaders: headers
            ),
            remainingRetries: settings.maxRetries
        )
    }

    public func put(
        path: String,
        headers: [String: String]? = nil
    ) async throws {
        let url = try requestBuilder.buildURL(path: path)
        try await performRequestWithoutResponse(
            url: url,
            method: .put,
            headers: requestBuilder.buildHeaders(
                for: .put,
                additionalHeaders: headers
            ),
            remainingRetries: settings.maxRetries
        )
    }

    public func put<E: Encodable>(
        path: String,
        body: E,
        headers: [String: String]? = nil
    ) async throws {
        let url = try requestBuilder.buildURL(path: path)
        try await performRequestWithoutResponse(
            url: url,
            method: .put,
            body: body,
            headers: requestBuilder.buildHeaders(
                for: .put,
                additionalHeaders: headers
            ),
            remainingRetries: settings.maxRetries
        )
    }

    public func patch(
        path: String,
        headers: [String: String]? = nil
    ) async throws {
        let url = try requestBuilder.buildURL(path: path)
        try await performRequestWithoutResponse(
            url: url,
            method: .patch,
            headers: requestBuilder.buildHeaders(
                for: .patch,
                additionalHeaders: headers
            ),
            remainingRetries: settings.maxRetries
        )
    }

    public func patch<E: Encodable>(
        path: String,
        body: E,
        headers: [String: String]? = nil
    ) async throws {
        let url = try requestBuilder.buildURL(path: path)
        try await performRequestWithoutResponse(
            url: url,
            method: .patch,
            body: body,
            headers: requestBuilder.buildHeaders(
                for: .patch,
                additionalHeaders: headers
            ),
            remainingRetries: settings.maxRetries
        )
    }

    public func delete(
        path: String,
        headers: [String: String]? = nil
    ) async throws {
        let url = try requestBuilder.buildURL(path: path)
        try await performRequestWithoutResponse(
            url: url,
            method: .delete,
            headers: requestBuilder.buildHeaders(
                for: .delete,
                additionalHeaders: headers
            ),
            remainingRetries: settings.maxRetries
        )
    }

    // MARK: - Upload Methods

    public func upload<T: Decodable>(
        path: String,
        headers: [String: String]? = nil,
        data: [MultipartData]
    ) async throws -> T {
        return try await performUploadWithResponse(
            path: path,
            headers: headers,
            data: data,
            remainingRetries: settings.maxRetries
        )
    }

    public func upload(
        path: String,
        headers: [String: String]? = nil,
        data: [MultipartData]
    ) async throws {
        try await performUploadWithoutResponse(
            path: path,
            headers: headers,
            data: data,
            remainingRetries: settings.maxRetries
        )
    }

    // MARK: - Private Request Methods

    private func performRequestWithResponse<T: Decodable>(
        url: URL,
        method: HTTPMethod,
        headers: HTTPHeaders,
        remainingRetries: Int
    ) async throws -> T {
        logRequest(method: method, url: url, headers: headers, remainingRetries: remainingRetries)

        return try await withCheckedThrowingContinuation { continuation in
            session.request(url, method: method, headers: headers)
                .validate()
                .responseDecodable(of: T.self, decoder: decoder) {
                    [weak self] response in
                    guard let self = self else { return }

                    // Create retry handler closure only if retries remain
                    let retryHandler: (() async throws -> T)? =
                        remainingRetries > 0
                        ? { [weak self] () async throws -> T in
                            guard let self = self else {
                                throw NetworkClientError(
                                    code: "INTERNAL_ERROR",
                                    message: "NetworkClient was deallocated"
                                )
                            }
                            // Recreate request with potentially new token
                            let updatedHeaders = self.requestBuilder
                                .buildHeaders(
                                    for: method.toRequestType(),
                                    additionalHeaders: nil
                                )
                            return try await self.performRequestWithResponse(
                                url: url,
                                method: method,
                                headers: updatedHeaders,
                                remainingRetries: remainingRetries - 1
                            )
                        } : nil

                    self.responseHandler.handleResponseWithBody(
                        response: response,
                        continuation: continuation,
                        tokenRefreshHandler: self.tokenRefreshHandler,
                        retryHandler: retryHandler
                    )
                }
        }
    }

    private func performRequestWithResponse<T: Decodable, E: Encodable>(
        url: URL,
        method: HTTPMethod,
        headers: HTTPHeaders,
        body: E,
        remainingRetries: Int
    ) async throws -> T {
        logRequest(method: method, url: url, headers: headers, remainingRetries: remainingRetries, body: body)

        return try await withCheckedThrowingContinuation { continuation in
            session.request(
                url,
                method: method,
                parameters: body,
                encoder: JSONParameterEncoder.vivaParameterEncoder,
                headers: headers
            )
            .validate()
            .responseDecodable(of: T.self, decoder: decoder) {
                [weak self] response in
                guard let self = self else { return }

                // Create retry handler closure only if retries remain
                let retryHandler: (() async throws -> T)? =
                    remainingRetries > 0
                    ? { [weak self] () async throws -> T in
                        guard let self = self else {
                            throw NetworkClientError(
                                code: "INTERNAL_ERROR",
                                message: "NetworkClient was deallocated"
                            )
                        }
                        // Recreate request with potentially new token
                        let updatedHeaders = self.requestBuilder.buildHeaders(
                            for: method.toRequestType(),
                            additionalHeaders: nil
                        )
                        return try await self.performRequestWithResponse(
                            url: url,
                            method: method,
                            headers: updatedHeaders,
                            body: body,
                            remainingRetries: remainingRetries - 1
                        )
                    } : nil

                self.responseHandler.handleResponseWithBody(
                    response: response,
                    continuation: continuation,
                    tokenRefreshHandler: self.tokenRefreshHandler,
                    retryHandler: retryHandler
                )
            }
        }
    }

    private func performRequestWithoutResponse(
        url: URL,
        method: HTTPMethod,
        headers: HTTPHeaders,
        remainingRetries: Int
    ) async throws {
        logRequest(method: method, url: url, headers: headers, remainingRetries: remainingRetries)

        try await withCheckedThrowingContinuation { continuation in
            session.request(url, method: method, headers: headers)
                .validate()
                .response { [weak self] response in
                    guard let self = self else { return }

                    // Create retry handler closure only if retries remain
                    let retryHandler: (() async throws -> Void)? =
                        remainingRetries > 0
                        ? { [weak self] () async throws -> Void in
                            guard let self = self else {
                                throw NetworkClientError(
                                    code: "INTERNAL_ERROR",
                                    message: "NetworkClient was deallocated"
                                )
                            }
                            // Recreate request with potentially new token
                            let updatedHeaders = self.requestBuilder
                                .buildHeaders(
                                    for: method.toRequestType(),
                                    additionalHeaders: nil
                                )
                            try await self.performRequestWithoutResponse(
                                url: url,
                                method: method,
                                headers: updatedHeaders,
                                remainingRetries: remainingRetries - 1
                            )
                        } : nil

                    self.responseHandler.handleResponseWithoutBody(
                        response: response,
                        continuation: continuation,
                        tokenRefreshHandler: self.tokenRefreshHandler,
                        retryHandler: retryHandler
                    )
                }
        }
    }

    private func performRequestWithoutResponse<E: Encodable>(
        url: URL,
        method: HTTPMethod,
        body: E,
        headers: HTTPHeaders,
        remainingRetries: Int
    ) async throws {
        logRequest(method: method, url: url, headers: headers, remainingRetries: remainingRetries, body: body)

        try await withCheckedThrowingContinuation { continuation in
            session.request(
                url,
                method: method,
                parameters: body,
                encoder: JSONParameterEncoder.vivaParameterEncoder,
                headers: headers
            )
            .validate()
            .response { [weak self] response in
                guard let self = self else { return }

                // Create retry handler closure only if retries remain
                let retryHandler: (() async throws -> Void)? =
                    remainingRetries > 0
                    ? { [weak self] () async throws -> Void in
                        guard let self = self else {
                            throw NetworkClientError(
                                code: "INTERNAL_ERROR",
                                message: "NetworkClient was deallocated"
                            )
                        }
                        // Recreate request with potentially new token
                        let updatedHeaders = self.requestBuilder.buildHeaders(
                            for: method.toRequestType(),
                            additionalHeaders: nil
                        )
                        try await self.performRequestWithoutResponse(
                            url: url,
                            method: method,
                            body: body,
                            headers: updatedHeaders,
                            remainingRetries: remainingRetries - 1
                        )
                    } : nil

                self.responseHandler.handleResponseWithoutBody(
                    response: response,
                    continuation: continuation,
                    tokenRefreshHandler: self.tokenRefreshHandler,
                    retryHandler: retryHandler
                )
            }
        }
    }

    private func performUploadWithResponse<T: Decodable>(
        path: String,
        headers: [String: String]?,
        data: [MultipartData],
        remainingRetries: Int
    ) async throws -> T {
        let url = try requestBuilder.buildURL(path: path)
        let requestHeaders = requestBuilder.buildHeaders(
            for: .upload,
            additionalHeaders: headers
        )

        logRequest(method: .patch, url: url, headers: requestHeaders, remainingRetries: remainingRetries, fileCount: data.count)

        return try await withCheckedThrowingContinuation { continuation in
            session.upload(
                multipartFormData: { multipartFormData in
                    self.configureMultipartFormData(
                        multipartFormData,
                        with: data
                    )
                },
                to: url,
                method: .patch,
                headers: requestHeaders
            )
            .uploadProgress { progress in
                AppLogger.debugLocal(
                    "Upload progress: \(progress.fractionCompleted * 100)% (\(progress.completedUnitCount)/\(progress.totalUnitCount) bytes)",
                    category: .network
                )
            }
            .validate()
            .responseDecodable(of: T.self, decoder: decoder) {
                [weak self] response in
                guard let self = self else { return }

                // Create retry handler closure for uploads only if retries remain
                let retryHandler: (() async throws -> T)? =
                    remainingRetries > 0
                    ? { [weak self] () async throws -> T in
                        guard let self = self else {
                            throw NetworkClientError(
                                code: "INTERNAL_ERROR",
                                message: "NetworkClient was deallocated"
                            )
                        }
                        // Retry the upload with potentially new token
                        return try await self.performUploadWithResponse(
                            path: path,
                            headers: nil,
                            data: data,
                            remainingRetries: remainingRetries - 1
                        )
                    } : nil

                self.responseHandler.handleResponseWithBody(
                    response: response,
                    continuation: continuation,
                    tokenRefreshHandler: self.tokenRefreshHandler,
                    retryHandler: retryHandler
                )
            }
        }
    }

    private func performUploadWithoutResponse(
        path: String,
        headers: [String: String]?,
        data: [MultipartData],
        remainingRetries: Int
    ) async throws {
        let url = try requestBuilder.buildURL(path: path)
        let requestHeaders = requestBuilder.buildHeaders(
            for: .upload,
            additionalHeaders: headers
        )

        logRequest(method: .patch, url: url, headers: requestHeaders, remainingRetries: remainingRetries, fileCount: data.count)

        try await withCheckedThrowingContinuation { continuation in
            session.upload(
                multipartFormData: { multipartFormData in
                    self.configureMultipartFormData(
                        multipartFormData,
                        with: data
                    )
                },
                to: url,
                method: .patch,
                headers: requestHeaders
            )
            .uploadProgress { progress in
                AppLogger.debugLocal(
                    "Upload progress: \(progress.fractionCompleted * 100)% (\(progress.completedUnitCount)/\(progress.totalUnitCount) bytes)",
                    category: .network
                )
            }
            .validate()
            .response { [weak self] response in
                guard let self = self else { return }

                // Create retry handler closure for uploads without response only if retries remain
                let retryHandler: (() async throws -> Void)? =
                    remainingRetries > 0
                    ? { [weak self] () async throws -> Void in
                        guard let self = self else {
                            throw NetworkClientError(
                                code: "INTERNAL_ERROR",
                                message: "NetworkClient was deallocated"
                            )
                        }
                        // Retry the upload with potentially new token
                        try await self.performUploadWithoutResponse(
                            path: path,
                            headers: nil,
                            data: data,
                            remainingRetries: remainingRetries - 1
                        )
                    } : nil

                self.responseHandler.handleResponseWithoutBody(
                    response: response,
                    continuation: continuation,
                    tokenRefreshHandler: self.tokenRefreshHandler,
                    retryHandler: retryHandler
                )
            }
        }
    }

    // MARK: - Helper Methods

    private func logRequest(
        method: HTTPMethod,
        url: URL,
        headers: HTTPHeaders,
        remainingRetries: Int,
        body: (any Encodable)? = nil,
        fileCount: Int? = nil
    ) {
        // Skip logging for log requests to avoid log recursion
        if url.path == "/logs" {
            return
        }
        
        let currentAttempt = settings.maxRetries - remainingRetries + 1
        
        // Build request title with retry info if applicable
        var requestTitle = "🚀 \(method.rawValue) Request"
        if currentAttempt > 1 {
            requestTitle += " (retry \(currentAttempt - 1)/\(settings.maxRetries))"
        }
        
        var logMessage = "\(requestTitle)\n"
        logMessage += "URL: \(url.absoluteString)\n"
        
        // Format headers consistently
        let headersDict = Dictionary(uniqueKeysWithValues: headers.map { ($0.name, $0.value) })
        let filteredHeaders = headersDict.filter { $0.key != "Authorization" }
        logMessage += "Headers: \(filteredHeaders)"
        
        // Add file count for uploads
        if let fileCount = fileCount {
            logMessage += "\nFiles: \(fileCount)"
        }
        
        // Add body for requests with body
        if let body = body, settings.shouldLogBodies {
            if let jsonData = try? JSONEncoder.vivaEncoder.encode(body),
                let jsonObject = try? JSONSerialization.jsonObject(with: jsonData),
                let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
                let prettyString = String(data: prettyData, encoding: .utf8)
            {
                logMessage += "\nBody:\n\(prettyString)"
            } else {
                logMessage += "\nBody: \(body)"
            }
        }
        
        AppLogger.debugLocal(logMessage, category: .network)
    }

    private func configureMultipartFormData(
        _ multipartFormData: MultipartFormData,
        with data: [MultipartData]
    ) {
        var logMessage = "Configuring multipart form data:"

        data.forEach { dataItem in
            logMessage += "\n- File: \(dataItem.name)"
            multipartFormData.append(
                dataItem.data,
                withName: dataItem.name,
                fileName: dataItem.fileName,
                mimeType: dataItem.mimeType
            )
        }

        logMessage +=
            "\nTotal upload size: \(multipartFormData.contentLength) bytes"
        AppLogger.debugLocal(logMessage, category: .network)
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
            return .get  // Default case
        }
    }
}

// MARK: - Custom JSON Decoder Extension

extension JSONDecoder {
    static let vivaDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

// MARK: - Custom JSON Encoder Extension

extension JSONEncoder {
    static let vivaEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}

// MARK: - Custom JSONParameterEncoder

extension JSONParameterEncoder {
    static let vivaParameterEncoder: JSONParameterEncoder = {
        let encoder = JSONEncoder.vivaEncoder
        return JSONParameterEncoder(encoder: encoder)
    }()
}
