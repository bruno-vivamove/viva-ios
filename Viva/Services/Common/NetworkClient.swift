import Alamofire
import Foundation

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

final class NetworkClient<ErrorType: Decodable & Error> {
    private let session: Session
    private let decoder: JSONDecoder = JSONDecoder.vivaDecoder
    let settings: NetworkClientSettings
    
    private let defaultGetHeaders: [String: String] = [:]
    private let defaultPostHeaders = [
        "Content-Type": "application/json"
    ]
    private let defaultUploadHeaders: [String: String] = [:]
    
    init(settings: NetworkClientSettings) {
        self.settings = settings
        self.session = Session.default
        debugPrint("🔧 NetworkClient initialized with baseURL: \(settings.baseUrl)")
    }
    
    // MARK: - Request Building and Error Handling
    private func buildURL(path: String, queryParams: [String: Any]? = nil) throws -> URL {
        guard var components = URLComponents(string: settings.baseUrl + path) else {
            debugPrint("❌ Failed to create URL components with base: \(settings.baseUrl) and path: \(path)")
            throw NetworkClientError(code: "INVALID_URL", message: "Invalid URL")
        }
        
        if let queryParams = queryParams {
            components.queryItems = queryParams.map { key, value in
                URLQueryItem(name: key, value: String(describing: value))
            }
        }
        
        guard let url = components.url else {
            debugPrint("❌ Failed to create URL from components")
            throw NetworkClientError(code: "INVALID_URL", message: "Invalid URL")
        }
        
        debugPrint("🔨 Built URL: \(url.absoluteString)")
        return url
    }
    
    private func handleError<T>(
        _ error: AFError,
        response: DataResponse<T, AFError>,
        continuation: CheckedContinuation<T, Error>
    ) {
        debugPrint("❌ Error occurred during request")
        debugPrint("❌ Error description: \(error.localizedDescription)")

        if let underlyingError = error.underlyingError {
            debugPrint("❌ Underlying error: \(underlyingError)")
        }

        if let data = response.data,
           let errorResponse = try? decoder.decode(ErrorType.self, from: data)
        {
            debugPrint("❌ Decoded Error Response: \(errorResponse)")
            continuation.resume(throwing: errorResponse)
        } else {
            let networkError = NetworkClientError(
                code: "REQUEST_ERROR",
                message: error.localizedDescription
            )
            debugPrint("❌ Network Error: \(networkError)")
            if let data = response.data,
               let rawString = String(data: data, encoding: .utf8)
            {
                debugPrint("❌ Raw error response: \(rawString)")
            }
            continuation.resume(throwing: networkError)
        }
    }
    
    private func handleErrorWithoutResponse(
        _ error: AFError,
        response: AFDataResponse<Data?>,
        continuation: CheckedContinuation<Void, Error>
    ) {
        debugPrint("❌ Error occurred during request")
        debugPrint("❌ Error description: \(error.localizedDescription)")
        
        if let underlyingError = error.underlyingError {
            debugPrint("❌ Underlying error: \(underlyingError)")
        }
        
        if let data = response.data,
           let errorResponse = try? decoder.decode(ErrorType.self, from: data)
        {
            debugPrint("❌ Decoded Error Response: \(errorResponse)")
            continuation.resume(throwing: errorResponse)
        } else {
            let networkError = NetworkClientError(
                code: "REQUEST_ERROR",
                message: error.localizedDescription
            )
            debugPrint("❌ Network Error: \(networkError)")
            if let data = response.data,
               let rawString = String(data: data, encoding: .utf8)
            {
                debugPrint("❌ Raw error response: \(rawString)")
            }
            continuation.resume(throwing: networkError)
        }
    }
    // MARK: - Request Building
    private func buildHeaders(
        _ defaultHeaders: [String: String],
        _ additionalHeaders: [String: String]? = nil
    ) -> HTTPHeaders {
        let headers =
            defaultHeaders
            .merging(settings.headers) { _, new in new }
            .merging(additionalHeaders ?? [:]) { _, new in new }
        
        debugPrint("🔨 Built headers: \(headers.filter({$0.key != "Authorization"}))")
        return HTTPHeaders(headers)
    }
    
    // MARK: - Public Request Methods with Response
    
    public func get<T: Decodable>(
         path: String,
         queryParams: [String: Any]? = nil,
         headers: [String: String]? = nil
     ) async throws -> T {
         debugPrint("📤 GET Request initiated for path: \(path)")
         let url = try buildURL(path: path, queryParams: queryParams)
         return try await performRequestWithResponse(
             url: url,
             method: .get,
             headers: buildHeaders(defaultGetHeaders, headers)
         )
     }
     
     public func post<T: Decodable, E: Encodable>(
         path: String,
         headers: [String: String]? = nil,
         queryParams: [String: Any]? = nil,
         body: E
     ) async throws -> T {
         debugPrint("📤 POST Request initiated for path: \(path)")
         let url = try buildURL(path: path, queryParams: queryParams)
         return try await performRequestWithResponse(
             url: url,
             method: .post,
             headers: buildHeaders(defaultPostHeaders, headers),
             body: body
         )
     }
     
     public func post<T: Decodable>(
         path: String,
         queryParams: [String: Any]? = nil,
         headers: [String: String]? = nil
     ) async throws -> T {
         debugPrint("📤 POST Request initiated for path: \(path)")
         let url = try buildURL(path: path, queryParams: queryParams)
         return try await performRequestWithResponse(
             url: url,
             method: .post,
             headers: buildHeaders(defaultPostHeaders, headers)
         )
     }
    
    public func put<T: Decodable>(
        path: String,
        headers: [String: String]? = nil
    ) async throws -> T {
        debugPrint("📤 PUT Request with response initiated for path: \(path)")
        let url = try buildURL(path: path)
        return try await performRequestWithResponse(
            url: url,
            method: .put,
            headers: buildHeaders(defaultPostHeaders, headers)
        )
    }
    
    public func put<T: Decodable, E: Encodable>(
        path: String,
        body: E,
        headers: [String: String]? = nil
    ) async throws -> T {
        debugPrint("📤 PUT Request with body and response initiated for path: \(path)")
        let url = try buildURL(path: path)
        return try await performRequestWithResponse(
            url: url,
            method: .put,
            headers: buildHeaders(defaultPostHeaders, headers),
            body: body
        )
    }
    
    // MARK: - Public Request Methods without Response
    
    public func post(
        path: String,
        headers: [String: String]? = nil
    ) async throws {
        debugPrint("📤 POST Request (no response) initiated for path: \(path)")
        let url = try buildURL(path: path)
        try await performRequestWithoutResponse(
            url: url,
            method: .post,
            headers: buildHeaders(defaultPostHeaders, headers)
        )
    }
    
    public func post<E: Encodable>(
        path: String,
        body: E,
        headers: [String: String]? = nil
    ) async throws {
        debugPrint("📤 POST Request (no response) with body initiated for path: \(path)")
        let url = try buildURL(path: path)
        try await performRequestWithoutResponse(
            url: url,
            method: .post,
            body: body,
            headers: buildHeaders(defaultPostHeaders, headers)
        )
    }
    
    public func put(
        path: String,
        headers: [String: String]? = nil
    ) async throws {
        debugPrint("📤 PUT Request initiated for path: \(path)")
        let url = try buildURL(path: path)
        try await performRequestWithoutResponse(
            url: url,
            method: .put,
            headers: buildHeaders(defaultPostHeaders, headers)
        )
    }
    
    public func put<E: Encodable>(
        path: String,
        body: E,
        headers: [String: String]? = nil
    ) async throws {
        debugPrint("📤 PUT Request with body initiated for path: \(path)")
        let url = try buildURL(path: path)
        try await performRequestWithoutResponse(
            url: url,
            method: .put,
            body: body,
            headers: buildHeaders(defaultPostHeaders, headers)
        )
    }
    
    public func patch(
        path: String,
        headers: [String: String]? = nil
    ) async throws {
        debugPrint("📤 PATCH Request initiated for path: \(path)")
        let url = try buildURL(path: path)
        try await performRequestWithoutResponse(
            url: url,
            method: .patch,
            headers: buildHeaders(defaultPostHeaders, headers)
        )
    }
    
    public func patch<E: Encodable>(
        path: String,
        body: E,
        headers: [String: String]? = nil
    ) async throws {
        debugPrint("📤 PATCH Request with body initiated for path: \(path)")
        let url = try buildURL(path: path)
        try await performRequestWithoutResponse(
            url: url,
            method: .patch,
            body: body,
            headers: buildHeaders(defaultPostHeaders, headers)
        )
    }
    
    public func delete(
        path: String,
        headers: [String: String]? = nil
    ) async throws {
        debugPrint("📤 DELETE Request initiated for path: \(path)")
        let url = try buildURL(path: path)
        try await performRequestWithoutResponse(
            url: url,
            method: .delete,
            headers: buildHeaders(defaultGetHeaders, headers)
        )
    }
    
    // MARK: - Upload Methods
    
    public func upload<T: Decodable>(
        path: String,
        headers: [String: String]? = nil,
        data: [MultipartData]
    ) async throws -> T {
        debugPrint("📤 Upload Request initiated for path: \(path)")
        let url = try buildURL(path: path)
        let requestHeaders = buildHeaders(defaultUploadHeaders, headers)
        
        debugPrint("🌐 Upload Request: \(url.absoluteString)")
        debugPrint("📋 Headers: \(requestHeaders.filter({$0.name != "Authorization"}))")
        debugPrint("📦 Uploading \(data.count) files")
        
        return try await withCheckedThrowingContinuation { continuation in
            session.upload(
                multipartFormData: { multipartFormData in
                    data.forEach { dataItem in
                        debugPrint("📎 Appending file: \(dataItem.name)")
                        multipartFormData.append(
                            dataItem.data,
                            withName: dataItem.name,
                            fileName: dataItem.fileName,
                            mimeType: dataItem.mimeType
                        )
                    }
                    debugPrint(
                        "📦 Total upload size: \(multipartFormData.contentLength) bytes"
                    )
                },
                to: url,
                method: .patch,
                headers: requestHeaders
            )
            .uploadProgress { progress in
                debugPrint(
                    "📤 Upload progress: \(progress.fractionCompleted * 100)% (\(progress.completedUnitCount)/\(progress.totalUnitCount) bytes)"
                )
            }
            .validate()
            .responseDecodable(of: T.self, decoder: decoder) { response in
                switch response.result {
                case .success(let value):
                    debugPrint("✅ Upload completed successfully")
                    continuation.resume(returning: value)
                case .failure(let error):
                    self.handleError(
                        error, response: response, continuation: continuation)
                }
            }
        }
    }
    
    public func upload(
        path: String,
        headers: [String: String]? = nil,
        data: [MultipartData]
    ) async throws {
        debugPrint("📤 Upload Request (no response) initiated for path: \(path)")
        let url = try buildURL(path: path)
        let requestHeaders = buildHeaders(defaultUploadHeaders, headers)
        
        debugPrint("🌐 Upload Request: \(url.absoluteString)")
        debugPrint("📋 Headers: \(requestHeaders.filter({$0.name != "Authorization"}))")
        debugPrint("📦 Uploading \(data.count) files")
        
        try await withCheckedThrowingContinuation { continuation in
            session.upload(
                multipartFormData: { multipartFormData in
                    data.forEach { dataItem in
                        debugPrint("📎 Appending file: \(dataItem.name)")
                        multipartFormData.append(
                            dataItem.data,
                            withName: dataItem.name,
                            fileName: dataItem.fileName,
                            mimeType: dataItem.mimeType
                        )
                    }
                    debugPrint(
                        "📦 Total upload size: \(multipartFormData.contentLength) bytes"
                    )
                },
                to: url,
                method: .patch,
                headers: requestHeaders
            )
            .uploadProgress { progress in
                debugPrint(
                    "📤 Upload progress: \(progress.fractionCompleted * 100)% (\(progress.completedUnitCount)/\(progress.totalUnitCount) bytes)"
                )
            }
            .validate()
            .response { response in
                switch response.result {
                case .success:
                    debugPrint("✅ Upload completed successfully")
                    continuation.resume()
                case .failure(let error):
                    self.handleErrorWithoutResponse(
                        error, response: response, continuation: continuation)
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
        debugPrint("🌐 \(method.rawValue) Request: \(url.absoluteString)")
        debugPrint("📋 Headers: \(headers.filter({$0.name != "Authorization"}))")

        return try await withCheckedThrowingContinuation { continuation in
            session.request(url, method: method, headers: headers)
                .validate()
                .responseDecodable(of: T.self, decoder: decoder) { response in
                    debugPrint("🌐 Attempting to decode to type: \(T.self)")
                    debugPrint(
                        "📥 Response Status: \(String(describing: response.response?.statusCode))"
                    )
                    debugPrint(
                        "📥 Response Headers: \(String(describing: response.response?.headers))"
                    )
                    
                    if let data = response.data {
                        debugPrint("📥 Response size: \(data.count) bytes")
                        if let rawString = String(data: data, encoding: .utf8) {
                            debugPrint("📥 Raw Response string: \(rawString)")
                        }
                    }
                    
                    switch response.result {
                    case .success(let value):
                        debugPrint("✅ Request completed successfully")
                        continuation.resume(returning: value)
                    case .failure(let error):
                        self.handleError(
                            error, response: response,
                            continuation: continuation)
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
        debugPrint("🌐 \(method.rawValue) Request: \(url.absoluteString)")
        debugPrint("📋 Headers: \(headers.filter({$0.name != "Authorization"}))")
        debugPrint("📦 Body: \(body)")
        
        return try await withCheckedThrowingContinuation { continuation in
            session.request(
                url,
                method: method,
                parameters: body,
                encoder: JSONParameterEncoder.default,
                headers: headers
            )
            .validate()
            .responseDecodable(of: T.self, decoder: decoder) { response in
                debugPrint("🌐 Attempting to decode to type: \(T.self)")
                debugPrint(
                    "📥 Response Status: \(String(describing: response.response?.statusCode))"
                )
                debugPrint(
                    "📥 Response Headers: \(String(describing: response.response?.headers))"
                )
                
                if let data = response.data {
                    debugPrint("📥 Response size: \(data.count) bytes")
                    if let rawString = String(data: data, encoding: .utf8) {
                        debugPrint("📥 Raw Response string: \(rawString)")
                    }
                }
                
                switch response.result {
                case .success(let value):
                    debugPrint("✅ Request completed successfully")
                    continuation.resume(returning: value)
                case .failure(let error):
                    self.handleError(
                        error, response: response,
                        continuation: continuation)
                }
            }
        }
    }
    
    private func performRequestWithoutResponse(
            url: URL,
            method: HTTPMethod,
            headers: HTTPHeaders
        ) async throws {
            debugPrint("🌐 \(method.rawValue) Request: \(url.absoluteString)")
            debugPrint("📋 Headers: \(headers.filter({$0.name != "Authorization"}))")

            try await withCheckedThrowingContinuation { continuation in
                session.request(url, method: method, headers: headers)
                    .validate()
                    .response { response in
                        debugPrint(
                            "📥 Response Status: \(String(describing: response.response?.statusCode))"
                        )
                        debugPrint(
                            "📥 Response Headers: \(String(describing: response.response?.headers))"
                        )
                        
                        if let data = response.data {
                            debugPrint("📥 Response size: \(data.count) bytes")
                            if let rawString = String(data: data, encoding: .utf8) {
                                debugPrint("📥 Raw Response string: \(rawString)")
                            }
                        }
                        
                        switch response.result {
                        case .success:
                            debugPrint("✅ Request completed successfully")
                            continuation.resume()
                        case .failure(let error):
                            self.handleErrorWithoutResponse(
                                error, response: response,
                                continuation: continuation)
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
            debugPrint("🌐 \(method.rawValue) Request: \(url.absoluteString)")
            debugPrint("📋 Headers: \(headers.filter({$0.name != "Authorization"}))")
            debugPrint("📦 Body: \(body)")
            
            try await withCheckedThrowingContinuation { continuation in
                session.request(
                    url,
                    method: method,
                    parameters: body,
                    encoder: JSONParameterEncoder.default,
                    headers: headers
                )
                .validate()
                .response { response in
                    debugPrint(
                        "📥 Response Status: \(String(describing: response.response?.statusCode))"
                    )
                    debugPrint(
                        "📥 Response Headers: \(String(describing: response.response?.headers))"
                    )
                    
                    if let data = response.data {
                        debugPrint("📥 Response size: \(data.count) bytes")
                        if let rawString = String(data: data, encoding: .utf8) {
                            debugPrint("📥 Raw Response string: \(rawString)")
                        }
                    }
                    
                    switch response.result {
                    case .success:
                        debugPrint("✅ Request completed successfully")
                        continuation.resume()
                    case .failure(let error):
                        self.handleErrorWithoutResponse(
                            error, response: response, continuation: continuation)
                    }
                }
            }
        }
    }
