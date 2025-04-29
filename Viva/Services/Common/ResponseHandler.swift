import Alamofire
import Foundation

final class ResponseHandler<ErrorType: Decodable & Error> {
    private let decoder: JSONDecoder
    private let shouldLogBodies: Bool
    private let errorManager: ErrorManager?

    init(
        decoder: JSONDecoder,
        shouldLogBodies: Bool = false,
        errorManager: ErrorManager? = nil
    ) {
        self.decoder = decoder
        self.shouldLogBodies = shouldLogBodies
        self.errorManager = errorManager
    }

    // MARK: - Handle Response

    func handleResponse<T>(
        response: DataResponse<T, AFError>,
        continuation: CheckedContinuation<T, Error>,
        tokenRefreshHandler: TokenRefreshHandler? = nil,
        retryHandler: (() async throws -> T)? = nil
    ) {
        logResponse(response)

        switch response.result {
        case .success(let value):
            handleSuccess(value, continuation: continuation)
        case .failure(let error):
            if let tokenRefreshHandler = tokenRefreshHandler,
                let retryHandler = retryHandler
            {
                handleError(
                    error,
                    response: response,
                    continuation: continuation,
                    tokenRefreshHandler: tokenRefreshHandler,
                    retryHandler: retryHandler
                )
            } else {
                handleError(
                    error,
                    response: response,
                    continuation: continuation
                )
            }
        }
    }

    func handleResponseWithoutResponse(
        response: AFDataResponse<Data?>,
        continuation: CheckedContinuation<Void, Error>,
        tokenRefreshHandler: TokenRefreshHandler? = nil,
        retryHandler: (() async throws -> Void)? = nil
    ) {
        logResponse(response)

        switch response.result {
        case .success:
            handleSuccessWithoutResponse(continuation: continuation)
        case .failure(let error):
            if let tokenRefreshHandler = tokenRefreshHandler,
                let retryHandler = retryHandler
            {
                handleErrorWithoutResponse(
                    error,
                    response: response,
                    continuation: continuation,
                    tokenRefreshHandler: tokenRefreshHandler,
                    retryHandler: retryHandler
                )
            } else {
                handleErrorWithoutResponse(
                    error,
                    response: response,
                    continuation: continuation
                )
            }
        }
    }

    // MARK: - Success Handlers

    func handleSuccess<T>(
        _ value: T,
        continuation: CheckedContinuation<T, Error>
    ) {
        // Clear any network errors on successful response
        errorManager?.clearError(type: .network)
        continuation.resume(returning: value)
    }

    func handleSuccessWithoutResponse(
        continuation: CheckedContinuation<Void, Error>
    ) {
        // Clear any network errors on successful response
        errorManager?.clearError(type: .network)
        continuation.resume()
    }

    // MARK: - Error Handlers

    func handleError<T>(
        _ error: AFError,
        response: DataResponse<T, AFError>,
        continuation: CheckedContinuation<T, Error>
    ) {
        AppLogger.error(
            "Error occurred during request: \(error.localizedDescription)",
            category: .network
        )

        if let underlyingError = error.underlyingError {
            AppLogger.error(
                "Underlying error: \(underlyingError)",
                category: .network
            )
        }

        if let data = response.data,
            let errorResponse = try? decoder.decode(ErrorType.self, from: data)
        {
            AppLogger.error(
                "Decoded Error Response: \(errorResponse)",
                category: .network
            )
            continuation.resume(throwing: errorResponse)
        } else {
            // Determine the appropriate network error type based on the error
            let networkError: NetworkClientError

            if let urlError = error.underlyingError as? URLError {
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost:
                    networkError = NetworkClientError.connectionError()
                case .timedOut:
                    networkError = NetworkClientError.timeoutError()
                default:
                    networkError = NetworkClientError.requestError(
                        message: error.localizedDescription
                    )
                }
            } else if response.response?.statusCode == 500 {
                networkError = NetworkClientError.serverError()
            } else if response.response?.statusCode == 401 {
                networkError = NetworkClientError.authenticationError()
            } else {
                networkError = NetworkClientError.requestError(
                    message: error.localizedDescription
                )
            }

            AppLogger.error(
                "Network Error: \(networkError)",
                category: .network
            )
            if let data = response.data,
                let rawString = String(data: data, encoding: .utf8)
            {
                AppLogger.error(
                    "Raw error response: \(rawString)",
                    category: .network
                )
            }

            // Display the error in the UI if errorManager is available
            errorManager?.displayError(
                networkError.userFriendlyMessage,
                type: .network
            )

            continuation.resume(throwing: networkError)
        }
    }

    func handleError<T>(
        _ error: AFError,
        response: DataResponse<T, AFError>,
        continuation: CheckedContinuation<T, Error>,
        tokenRefreshHandler: TokenRefreshHandler?,
        retryHandler: (() async throws -> T)?
    ) {
        // Check if the error is a 401 Unauthorized and we have a refresh handler
        if let tokenRefreshHandler = tokenRefreshHandler,
            let retryHandler = retryHandler,
            isUnauthorizedError(response.response)
        {

            Task {
                do {
                    // Attempt to refresh the token using the actor
                    try await tokenRefreshHandler.handleUnauthorizedError()

                    // Retry the original request with the new token
                    let result = try await retryHandler()
                    continuation.resume(returning: result)
                } catch {
                    // If refresh fails, return the original error
                    AppLogger.error(
                        "Request retry after token refresh failed: \(error.localizedDescription)",
                        category: .network
                    )

                    // Update authentication error message
                    errorManager?.displayError(
                        "Session expired. Please log in again.",
                        type: .authentication
                    )

                    continuation.resume(throwing: error)
                }
            }
        } else {
            // Handle error normally for non-401 errors or when we don't have a refresh handler
            AppLogger.error(
                "Error occurred during request: \(error.localizedDescription)",
                category: .network
            )

            if let underlyingError = error.underlyingError {
                AppLogger.error(
                    "Underlying error: \(underlyingError)",
                    category: .network
                )
            }

            if let data = response.data,
                let errorResponse = try? decoder.decode(
                    ErrorType.self,
                    from: data
                )
            {
                AppLogger.error(
                    "Decoded Error Response: \(errorResponse)",
                    category: .network
                )
                continuation.resume(throwing: errorResponse)
            } else {
                // Determine the appropriate network error type based on the error
                let networkError: NetworkClientError

                if let urlError = error.underlyingError as? URLError {
                    switch urlError.code {
                    case .notConnectedToInternet, .networkConnectionLost:
                        networkError = NetworkClientError.connectionError()
                    case .timedOut:
                        networkError = NetworkClientError.timeoutError()
                    default:
                        networkError = NetworkClientError.requestError(
                            message: error.localizedDescription
                        )
                    }
                } else if response.response?.statusCode == 500 {
                    networkError = NetworkClientError.serverError()
                } else if response.response?.statusCode == 401 {
                    networkError = NetworkClientError.authenticationError()
                } else {
                    networkError = NetworkClientError.requestError(
                        message: error.localizedDescription
                    )
                }

                AppLogger.error(
                    "Network Error: \(networkError)",
                    category: .network
                )
                if let data = response.data,
                    let rawString = String(data: data, encoding: .utf8)
                {
                    AppLogger.error(
                        "Raw error response: \(rawString)",
                        category: .network
                    )
                }

                // Display the network error in the UI
                errorManager?.displayError(
                    networkError.userFriendlyMessage,
                    type: .network
                )

                continuation.resume(throwing: networkError)
            }
        }
    }

    func handleErrorWithoutResponse(
        _ error: AFError,
        response: AFDataResponse<Data?>,
        continuation: CheckedContinuation<Void, Error>
    ) {
        AppLogger.error(
            "Error occurred during request: \(error.localizedDescription)",
            category: .network
        )

        if let underlyingError = error.underlyingError {
            AppLogger.error(
                "Underlying error: \(underlyingError)",
                category: .network
            )
        }

        if let data = response.data,
            let errorResponse = try? decoder.decode(ErrorType.self, from: data)
        {
            AppLogger.error(
                "Decoded Error Response: \(errorResponse)",
                category: .network
            )
            continuation.resume(throwing: errorResponse)
        } else {
            // Determine the appropriate network error type based on the error
            let networkError: NetworkClientError

            if let urlError = error.underlyingError as? URLError {
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost:
                    networkError = NetworkClientError.connectionError()
                case .timedOut:
                    networkError = NetworkClientError.timeoutError()
                default:
                    networkError = NetworkClientError.requestError(
                        message: error.localizedDescription
                    )
                }
            } else if response.response?.statusCode == 500 {
                networkError = NetworkClientError.serverError()
            } else if response.response?.statusCode == 401 {
                networkError = NetworkClientError.authenticationError()
            } else {
                networkError = NetworkClientError.requestError(
                    message: error.localizedDescription
                )
            }

            AppLogger.error(
                "Network Error: \(networkError)",
                category: .network
            )
            if let data = response.data,
                let rawString = String(data: data, encoding: .utf8)
            {
                AppLogger.error(
                    "Raw error response: \(rawString)",
                    category: .network
                )
            }

            // Display the network error in the UI
            errorManager?.displayError(
                networkError.userFriendlyMessage,
                type: .network
            )

            continuation.resume(throwing: networkError)
        }
    }

    func handleErrorWithoutResponse(
        _ error: AFError,
        response: AFDataResponse<Data?>,
        continuation: CheckedContinuation<Void, Error>,
        tokenRefreshHandler: TokenRefreshHandler?,
        retryHandler: (() async throws -> Void)?
    ) {
        // Check if the error is a 401 Unauthorized and we have a refresh handler
        if let tokenRefreshHandler = tokenRefreshHandler,
            let retryHandler = retryHandler,
            isUnauthorizedError(response.response)
        {

            // Display authentication error
            errorManager?.displayError(
                "Your session has expired. Attempting to renew...",
                type: .authentication
            )

            Task {
                do {
                    // Attempt to refresh the token using the actor
                    try await tokenRefreshHandler.handleUnauthorizedError()

                    // Clear the authentication error since refresh succeeded
                    errorManager?.clearError(type: .authentication)

                    // Retry the original request with the new token
                    try await retryHandler()
                    continuation.resume()
                } catch {
                    // If refresh fails, return the original error
                    AppLogger.error(
                        "Request retry after token refresh failed: \(error.localizedDescription)",
                        category: .network
                    )

                    // Update authentication error message
                    errorManager?.displayError(
                        "Session expired. Please log in again.",
                        type: .authentication
                    )

                    continuation.resume(throwing: error)
                }
            }
        } else {
            // Handle error normally for non-401 errors or when we don't have a refresh handler
            AppLogger.error(
                "Error occurred during request: \(error.localizedDescription)",
                category: .network
            )

            if let underlyingError = error.underlyingError {
                AppLogger.error(
                    "Underlying error: \(underlyingError)",
                    category: .network
                )
            }

            if let data = response.data,
                let errorResponse = try? decoder.decode(
                    ErrorType.self,
                    from: data
                )
            {
                AppLogger.error(
                    "Decoded Error Response: \(errorResponse)",
                    category: .network
                )
                continuation.resume(throwing: errorResponse)
            } else {
                let networkError = NetworkClientError(
                    code: "REQUEST_ERROR",
                    message: error.localizedDescription
                )
                AppLogger.error(
                    "Network Error: \(networkError)",
                    category: .network
                )
                if let data = response.data,
                    let rawString = String(data: data, encoding: .utf8)
                {
                    AppLogger.error(
                        "Raw error response: \(rawString)",
                        category: .network
                    )
                }

                // Display the network error in the UI
                errorManager?.displayError(
                    networkError.userFriendlyMessage,
                    type: .network
                )

                continuation.resume(throwing: networkError)
            }
        }
    }

    func isUnauthorizedError(_ response: HTTPURLResponse?) -> Bool {
        return response?.statusCode == 401
    }

    func logResponse<T>(_ response: DataResponse<T, AFError>) {
        var logMessage = ""

        // Add request information
        if let request = response.request {
            logMessage +=
                "Request URL: \(request.url?.absoluteString ?? "unknown")\n"
            logMessage += "Request Method: \(request.httpMethod ?? "unknown")\n"
            if let headers = request.allHTTPHeaderFields {
                logMessage +=
                    "Request Headers: \(headers.filter { $0.key != "Authorization" })\n"
            }
        }

        logMessage +=
            "Response Type: \(T.self)\n"
            + "Response Status: \(String(describing: response.response?.statusCode))\n"
            + "Response Headers: \(String(describing: response.response?.headers))"

        if let data = response.data {
            logMessage += "\nSize: \(data.count) bytes"
            if shouldLogBodies {
                if let jsonObject = try? JSONSerialization.jsonObject(with: data),
                   let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
                   let prettyString = String(data: prettyData, encoding: .utf8) {
                    logMessage += "\nRaw Response:\n\(prettyString)"
                } else if let rawString = String(data: data, encoding: .utf8) {
                    logMessage += "\nRaw Response: \(rawString)"
                }
            }
        }

        AppLogger.debug(logMessage, category: .network)
    }

    func logResponse(_ response: AFDataResponse<Data?>) {
        var logMessage = ""

        // Add request information
        if let request = response.request {
            logMessage +=
                "Request URL: \(request.url?.absoluteString ?? "unknown")\n"
            logMessage += "Request Method: \(request.httpMethod ?? "unknown")\n"
            if let headers = request.allHTTPHeaderFields {
                logMessage +=
                    "Request Headers: \(headers.filter { $0.key != "Authorization" })\n"
            }
        }

        logMessage +=
            "Response Status: \(String(describing: response.response?.statusCode))\n"
            + "Response Headers: \(String(describing: response.response?.headers))"

        if let data = response.data {
            logMessage += "\nSize: \(data.count) bytes"
            if shouldLogBodies {
                if let jsonObject = try? JSONSerialization.jsonObject(with: data),
                   let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
                   let prettyString = String(data: prettyData, encoding: .utf8) {
                    logMessage += "\nRaw Response:\n\(prettyString)"
                } else if let rawString = String(data: data, encoding: .utf8) {
                    logMessage += "\nRaw Response: \(rawString)"
                }
            }
        }

        AppLogger.debug(logMessage, category: .network)
    }
}
