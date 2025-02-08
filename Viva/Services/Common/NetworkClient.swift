import Alamofire
import Foundation

final class NetworkClient {
    private let session: Session
    private let settings: NetworkClientSettings

    private let defaultGetHeaders: [String: String] = [:]
    private let defaultPostHeaders = [
        "Content-Type": "application/json"
    ]
    private let defaultUploadHeaders: [String: String] = [:]

    init(settings: NetworkClientSettings) {
        self.settings = settings
        self.session = Session.default
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

        return HTTPHeaders(headers)
    }

    private func buildURL(path: String) throws -> URL {
        guard let url = URL(string: settings.baseUrl + path) else {
            throw NetworkClientError(
                code: "INVALID_URL",
                message: "Invalid URL"
            )
        }
        return url
    }

    // MARK: - Public Request Methods

    public func get<T: Decodable>(
        path: String,
        headers: [String: String]? = nil
    ) async throws -> T {
        let url = try buildURL(path: path)
        return try await performRequestWithoutBody(
            url: url,
            method: .get,
            headers: buildHeaders(defaultGetHeaders, headers)
        )
    }

    @discardableResult
    public func post<T: Decodable, E: Encodable>(
        path: String,
        body: E,
        headers: [String: String]? = nil
    ) async throws -> T {
        let url = try buildURL(path: path)
        return try await performRequestWithBody(
            url: url,
            method: .post,
            body: body,
            headers: buildHeaders(defaultPostHeaders, headers)
        )
    }

    @discardableResult
    public func post<T: Decodable>(
        path: String,
        headers: [String: String]? = nil
    ) async throws -> T {
        let url = try buildURL(path: path)
        return try await performRequestWithoutBody(
            url: url,
            method: .post,
            headers: buildHeaders(defaultPostHeaders, headers)
        )
    }

    @discardableResult
    public func put<T: Decodable, E: Encodable>(
        path: String,
        body: E,
        headers: [String: String]? = nil
    ) async throws -> T {
        let url = try buildURL(path: path)
        return try await performRequestWithBody(
            url: url,
            method: .put,
            body: body,
            headers: buildHeaders(defaultPostHeaders, headers)
        )
    }

    @discardableResult
    public func put<T: Decodable>(
        path: String,
        headers: [String: String]? = nil
    ) async throws -> T {
        let url = try buildURL(path: path)
        return try await performRequestWithoutBody(
            url: url,
            method: .put,
            headers: buildHeaders(defaultPostHeaders, headers)
        )
    }

    @discardableResult
    public func patch<T: Decodable, E: Encodable>(
        path: String,
        body: E,
        headers: [String: String]? = nil
    ) async throws -> T {
        let url = try buildURL(path: path)
        return try await performRequestWithBody(
            url: url,
            method: .patch,
            body: body,
            headers: buildHeaders(defaultPostHeaders, headers)
        )
    }

    @discardableResult
    public func patch<T: Decodable>(
        path: String,
        headers: [String: String]? = nil
    ) async throws -> T {
        let url = try buildURL(path: path)
        return try await performRequestWithoutBody(
            url: url,
            method: .patch,
            headers: buildHeaders(defaultPostHeaders, headers)
        )
    }

    struct MultipartData {
        let data: Data
        let name: String
        let fileName: String?
        let mimeType: String?

        init(
            data: Data, name: String, fileName: String? = nil,
            mimeType: String? = nil
        ) {
            self.data = data
            self.name = name
            self.fileName = fileName
            self.mimeType = mimeType
        }
    }

    @discardableResult
    func upload<T: Decodable>(
        path: String,
        headers: [String: String]? = nil,
        data: [MultipartData]
    ) async throws -> T {
        let url = try buildURL(path: path)
        let requestHeaders = buildHeaders(defaultUploadHeaders, headers)

        // Debug logging
        debugPrint("🌐 Upload Request: \(url.absoluteString)")
        debugPrint("📋 Headers: \(requestHeaders)")

        return try await withCheckedThrowingContinuation { continuation in
            session.upload(
                multipartFormData: { multipartFormData in
                    data.forEach { dataItem in
                        multipartFormData.append(
                            dataItem.data,
                            withName: dataItem.name,
                            fileName: dataItem.fileName,
                            mimeType: dataItem.mimeType
                        )
                    }
                },
                to: url,
                method: .patch,
                headers: requestHeaders
            )
            .uploadProgress { progress in
                debugPrint("📤 Upload progress: \(progress.fractionCompleted)")
            }
            .validate()
            .responseDecodable(of: T.self) { response in
                self.handleResponse(response, continuation: continuation)
            }
        }
    }

    @discardableResult
    public func delete<T: Decodable>(
        path: String,
        headers: [String: String]? = nil
    ) async throws -> T {
        let url = try buildURL(path: path)
        return try await performRequestWithoutBody(
            url: url,
            method: .delete,
            headers: buildHeaders(defaultGetHeaders, headers)
        )
    }

    // MARK: - Private Request Methods

    private func performRequestWithoutBody<T: Decodable>(
        url: URL,
        method: HTTPMethod,
        headers: HTTPHeaders
    ) async throws -> T {
        // Debug logging
        debugPrint("🌐 \(method.rawValue) Request: \(url.absoluteString)")
        debugPrint("📋 Headers: \(headers)")

        let decoder = JSONDecoder()
        return try await withCheckedThrowingContinuation { continuation in
            session.request(
                url,
                method: method,
                headers: headers
            )
            .validate()
            .responseDecodable(of: T.self, decoder: decoder) { response in
                self.handleResponse(response, continuation: continuation)
            }
        }
    }

    private func performRequestWithBody<T: Decodable, E: Encodable>(
        url: URL,
        method: HTTPMethod,
        body: E,
        headers: HTTPHeaders
    ) async throws -> T {
        // Debug logging
        debugPrint("🌐 \(method.rawValue) Request: \(url.absoluteString)")
        debugPrint("📋 Headers: \(headers)")
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
            .responseDecodable(of: T.self, emptyResponseCodes: [200, 204]) { response in
                self.handleResponse(response, continuation: continuation)
            }
        }
    }

    // MARK: - Response Handling

    private func handleResponse<T>(
        _ response: DataResponse<T, AFError>,
        continuation: CheckedContinuation<T, Error>
    ) {
        // Debug logging for response
        debugPrint("🌐 Attempting to decode to type: \(T.self)")
        debugPrint("📥 Response Status: \(String(describing: response.response?.statusCode))")
        debugPrint("📥 Response Headers: \(String(describing: response.response?.headers))")

        if let data = response.data {
            if let rawString = String(data: data, encoding: .utf8) {
                debugPrint("📥 Raw Response string: \(rawString)")
            }
        }

        switch response.result {
        case .success(let value):
            continuation.resume(returning: value)

        case .failure(let error):
            if let data = response.data,
                let errorResponse = try? JSONDecoder().decode(
                    ErrorResponse.self, from: data)
            {
                continuation.resume(throwing: errorResponse)
            } else {
                continuation.resume(
                    throwing: NetworkClientError(
                        code: "REQUEST_ERROR",
                        message: error.localizedDescription
                    ))
            }
        }
    }
}
