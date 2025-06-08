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

    func handleResponseWithBody<T>(
        response: DataResponse<T, AFError>,
        continuation: CheckedContinuation<T, Error>,
        tokenRefreshHandler: TokenRefreshHandler? = nil,
        retryHandler: (() async throws -> T)? = nil
    ) {
        logResponse(
            request: response.request,
            httpResponse: response.response,
            data: response.data,
            responseType: String(describing: T.self)
        )

        switch response.result {
        case .success(let value):
            // Clear any network errors on successful response
            Task { @MainActor in
                errorManager?.clearError(type: .network)
            }
            continuation.resume(returning: value)
        case .failure(let error):
            handleError(
                error: error,
                responseData: response.data,
                httpResponse: response.response,
                continuation: continuation,
                tokenRefreshHandler: tokenRefreshHandler,
                retryHandler: retryHandler
            )
        }
    }

    func handleResponseWithoutBody(
        response: AFDataResponse<Data?>,
        continuation: CheckedContinuation<Void, Error>,
        tokenRefreshHandler: TokenRefreshHandler? = nil,
        retryHandler: (() async throws -> Void)? = nil
    ) {
        logResponse(
            request: response.request,
            httpResponse: response.response,
            data: response.data,
            responseType: nil
        )

        switch response.result {
        case .success:
            // Clear any network errors on successful response
            Task { @MainActor in
                errorManager?.clearError(type: .network)
            }
            continuation.resume()
        case .failure(let error):
            handleError(
                error: error,
                responseData: response.data,
                httpResponse: response.response,
                continuation: continuation,
                tokenRefreshHandler: tokenRefreshHandler,
                retryHandler: retryHandler
            )
        }
    }

    // MARK: - Private Helper Methods

    private func handleError<T>(
        error: AFError,
        responseData: Data?,
        httpResponse: HTTPURLResponse?,
        continuation: CheckedContinuation<T, Error>,
        tokenRefreshHandler: TokenRefreshHandler?,
        retryHandler: (() async throws -> T)?
    ) {
        // Check if this is a 401 error and we have token refresh capability
        if let tokenRefreshHandler = tokenRefreshHandler,
           let retryHandler = retryHandler,
           isUnauthorizedError(httpResponse)
        {
            handleTokenRefreshAndRetry(
                error: error,
                continuation: continuation,
                tokenRefreshHandler: tokenRefreshHandler,
                retryHandler: retryHandler
            )
            return
        }
        
        // Check if we have a retry handler and there is no HTTP response (server unreachable)
        if let retryHandler = retryHandler,
           httpResponse == nil
        {
            handleRetryWithDelay(
                continuation: continuation,
                retryHandler: retryHandler
            )
            return
        }

        // Handle final error (no retry handler or after retries failed)
        handleFinalError(
            error: error,
            responseData: responseData,
            httpResponse: httpResponse,
            continuation: continuation
        )
    }
    
    private func handleRetryWithDelay<T>(
        continuation: CheckedContinuation<T, Error>,
        retryHandler: @escaping () async throws -> T
    ) {
        Task {
            do {
                // Add a 5-second delay before retry
                try await Task.sleep(nanoseconds: UInt64(5.0 * 1_000_000_000))
                
                let result = try await retryHandler()
                
                // Clear any network errors on successful retry
                Task { @MainActor in
                    errorManager?.clearError(type: .network)
                }
                continuation.resume(returning: result)
                
            } catch {
                AppLogger.error("Retry failed: \(error.localizedDescription)", category: .network)
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func handleFinalError<T>(
        error: AFError,
        responseData: Data?,
        httpResponse: HTTPURLResponse?,
        continuation: CheckedContinuation<T, Error>
    ) {
        // Try to decode custom error response first
        if let data = responseData,
            let errorResponse = try? decoder.decode(ErrorType.self, from: data)
        {

            let errorMessage = buildErrorMessage(
                error: error,
                decodedError: errorResponse
            )
            AppLogger.error(errorMessage, category: .network)
            continuation.resume(throwing: errorResponse)
            return
        }

        // Create network error and handle it
        let networkError = createNetworkError(
            from: error,
            httpResponse: httpResponse
        )
        let errorMessage = buildErrorMessage(
            error: error,
            networkError: networkError,
            responseData: responseData
        )

        AppLogger.error(errorMessage, category: .network)
        Task { @MainActor in
            errorManager?.registerError(
                networkError.userFriendlyMessage,
                type: .network
            )
        }
        
        continuation.resume(throwing: networkError)
    }

    private func handleTokenRefreshAndRetry<T>(
        error: AFError,
        continuation: CheckedContinuation<T, Error>,
        tokenRefreshHandler: TokenRefreshHandler,
        retryHandler: @escaping () async throws -> T
    ) {
        Task {
            do {
                // Attempt to refresh the token
                try await tokenRefreshHandler.handleUnauthorizedError()

                // Clear the authentication error since refresh succeeded (for void responses)
                if T.self == Void.self {
                    Task { @MainActor in
                        errorManager?.clearError(type: .authentication)
                    }
                }

                // Retry the original request with the new token
                let result = try await retryHandler()
                continuation.resume(returning: result)
            } catch {
                // If refresh fails, handle the original error
                AppLogger.error(
                    "Request retry after token refresh failed: \(error.localizedDescription)",
                    category: .network
                )

                // TODO Decide what we want to do here
//                Task { @MainActor in
//                    errorManager?.registerError(
//                        "Session expired. Please log in again.",
//                        type: .authentication
//                    )
//                }

                continuation.resume(throwing: error)
            }
        }
    }

    private func createNetworkError(
        from error: AFError,
        httpResponse: HTTPURLResponse?
    ) -> NetworkClientError {
        if let urlError = error.underlyingError as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return NetworkClientError.connectionError()
            case .timedOut:
                return NetworkClientError.timeoutError()
            default:
                return NetworkClientError.requestError(
                    message: error.localizedDescription
                )
            }
        } else if httpResponse?.statusCode == 500 {
            return NetworkClientError.serverError()
        } else if httpResponse?.statusCode == 401 {
            return NetworkClientError.authenticationError()
        } else {
            return NetworkClientError.requestError(
                message: error.localizedDescription
            )
        }
    }

    private func buildErrorMessage(error: AFError, decodedError: any Error)
        -> String
    {
        var errorMessage =
            "Error occurred during request: \(error.localizedDescription)"

        if let underlyingError = error.underlyingError {
            errorMessage += "\nUnderlying error: \(underlyingError)"
        }

        errorMessage += "\nDecoded Error Response: \(decodedError)"
        return errorMessage
    }

    private func buildErrorMessage(
        error: AFError,
        networkError: NetworkClientError,
        responseData: Data?
    ) -> String {
        var errorMessage =
            "Error occurred during request: \(error.localizedDescription)"

        if let underlyingError = error.underlyingError {
            errorMessage += "\nUnderlying error: \(underlyingError)"
        }

        errorMessage += "\nNetwork Error: \(networkError)"

        if let data = responseData,
            let rawString = String(data: data, encoding: .utf8)
        {
            errorMessage += "\nRaw error response: \(rawString)"
        }

        return errorMessage
    }

    private func isUnauthorizedError(_ response: HTTPURLResponse?) -> Bool {
        return response?.statusCode == 401
    }

    // MARK: - Response Logging

    private func logResponse(
        request: URLRequest?,
        httpResponse: HTTPURLResponse?,
        data: Data?,
        responseType: String?
    ) {
        var logMessage = ""

        // Add request information
        if let request = request {
            logMessage +=
                "Request: \(request.httpMethod ?? "unknown") \(request.url?.absoluteString ?? "unknown")\n"
            if let headers = request.allHTTPHeaderFields {
                logMessage +=
                    "Request Headers: \(headers.filter { $0.key != "Authorization" })\n"
            }
        }

        if let responseType = responseType {
            logMessage += "Response Type: \(responseType)\n"
        }

        // Add icon based on status code
        let statusCode = httpResponse?.statusCode ?? 0
        let responseIcon = statusCode >= 400 ? "❌" : "✅"
        logMessage +=
            "\(responseIcon) Response Status: \(String(describing: httpResponse?.statusCode))\n"
        logMessage +=
            "Response Headers: \(String(describing: httpResponse?.headers))"

        if let data = data {
            logMessage += "\nSize: \(data.count) bytes"
            if shouldLogBodies {
                if let jsonObject = try? JSONSerialization.jsonObject(
                    with: data
                ),
                    let prettyData = try? JSONSerialization.data(
                        withJSONObject: jsonObject,
                        options: .prettyPrinted
                    ),
                    let prettyString = String(data: prettyData, encoding: .utf8)
                {
                    logMessage += "\nRaw Response:\n\(prettyString)"
                } else if let rawString = String(data: data, encoding: .utf8) {
                    logMessage += "\nRaw Response: \(rawString)"
                }
            }
        }

        AppLogger.debug(logMessage, category: .network)
    }
}
