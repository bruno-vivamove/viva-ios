import Alamofire
import Foundation

final class ResponseHandler<ErrorType: Decodable & Error> {
    private let decoder: JSONDecoder
    private let shouldLogBodies: Bool
    
    init(decoder: JSONDecoder, shouldLogBodies: Bool = false) {
        self.decoder = decoder
        self.shouldLogBodies = shouldLogBodies
    }
    
    func handleError<T>(
        _ error: AFError,
        response: DataResponse<T, AFError>,
        continuation: CheckedContinuation<T, Error>
    ) {
        AppLogger.error("Error occurred during request: \(error.localizedDescription)", category: .network)
        
        if let underlyingError = error.underlyingError {
            AppLogger.error("Underlying error: \(underlyingError)", category: .network)
        }
        
        if let data = response.data,
           let errorResponse = try? decoder.decode(ErrorType.self, from: data) {
            AppLogger.error("Decoded Error Response: \(errorResponse)", category: .network)
            continuation.resume(throwing: errorResponse)
        } else {
            let networkError = NetworkClientError(
                code: "REQUEST_ERROR",
                message: error.localizedDescription
            )
            AppLogger.error("Network Error: \(networkError)", category: .network)
            if let data = response.data,
               let rawString = String(data: data, encoding: .utf8) {
                AppLogger.error("Raw error response: \(rawString)", category: .network)
            }
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
           isUnauthorizedError(response.response) {
            
            Task {
                do {
                    // Attempt to refresh the token using the actor
                    try await tokenRefreshHandler.handleUnauthorizedError()
                    
                    // Retry the original request with the new token
                    let result = try await retryHandler()
                    continuation.resume(returning: result)
                } catch {
                    // If refresh fails, return the original error
                    AppLogger.error("Request retry after token refresh failed: \(error.localizedDescription)", category: .network)
                    continuation.resume(throwing: error)
                }
            }
        } else {
            // Handle error normally for non-401 errors or when we don't have a refresh handler
            AppLogger.error("Error occurred during request: \(error.localizedDescription)", category: .network)
            
            if let underlyingError = error.underlyingError {
                AppLogger.error("Underlying error: \(underlyingError)", category: .network)
            }
            
            if let data = response.data,
               let errorResponse = try? decoder.decode(ErrorType.self, from: data) {
                AppLogger.error("Decoded Error Response: \(errorResponse)", category: .network)
                continuation.resume(throwing: errorResponse)
            } else {
                let networkError = NetworkClientError(
                    code: "REQUEST_ERROR",
                    message: error.localizedDescription
                )
                AppLogger.error("Network Error: \(networkError)", category: .network)
                if let data = response.data,
                   let rawString = String(data: data, encoding: .utf8) {
                    AppLogger.error("Raw error response: \(rawString)", category: .network)
                }
                continuation.resume(throwing: networkError)
            }
        }
    }
    
    func handleErrorWithoutResponse(
        _ error: AFError,
        response: AFDataResponse<Data?>,
        continuation: CheckedContinuation<Void, Error>
    ) {
        AppLogger.error("Error occurred during request: \(error.localizedDescription)", category: .network)
        
        if let underlyingError = error.underlyingError {
            AppLogger.error("Underlying error: \(underlyingError)", category: .network)
        }
        
        if let data = response.data,
           let errorResponse = try? decoder.decode(ErrorType.self, from: data) {
            AppLogger.error("Decoded Error Response: \(errorResponse)", category: .network)
            continuation.resume(throwing: errorResponse)
        } else {
            let networkError = NetworkClientError(
                code: "REQUEST_ERROR",
                message: error.localizedDescription
            )
            AppLogger.error("Network Error: \(networkError)", category: .network)
            if let data = response.data,
               let rawString = String(data: data, encoding: .utf8) {
                AppLogger.error("Raw error response: \(rawString)", category: .network)
            }
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
           isUnauthorizedError(response.response) {
            
            Task {
                do {
                    // Attempt to refresh the token using the actor
                    try await tokenRefreshHandler.handleUnauthorizedError()
                    
                    // Retry the original request with the new token
                    try await retryHandler()
                    continuation.resume()
                } catch {
                    // If refresh fails, return the original error
                    AppLogger.error("Request retry after token refresh failed: \(error.localizedDescription)", category: .network)
                    continuation.resume(throwing: error)
                }
            }
        } else {
            // Handle error normally for non-401 errors or when we don't have a refresh handler
            AppLogger.error("Error occurred during request: \(error.localizedDescription)", category: .network)
            
            if let underlyingError = error.underlyingError {
                AppLogger.error("Underlying error: \(underlyingError)", category: .network)
            }
            
            if let data = response.data,
               let errorResponse = try? decoder.decode(ErrorType.self, from: data) {
                AppLogger.error("Decoded Error Response: \(errorResponse)", category: .network)
                continuation.resume(throwing: errorResponse)
            } else {
                let networkError = NetworkClientError(
                    code: "REQUEST_ERROR",
                    message: error.localizedDescription
                )
                AppLogger.error("Network Error: \(networkError)", category: .network)
                if let data = response.data,
                   let rawString = String(data: data, encoding: .utf8) {
                    AppLogger.error("Raw error response: \(rawString)", category: .network)
                }
                continuation.resume(throwing: networkError)
            }
        }
    }
    
    func isUnauthorizedError(_ response: HTTPURLResponse?) -> Bool {
        return response?.statusCode == 401
    }
    
    func logResponse<T>(_ response: DataResponse<T, AFError>) {
        var logMessage = "Response:\nType: \(T.self)\nStatus: \(String(describing: response.response?.statusCode))\nHeaders: \(String(describing: response.response?.headers))"
        
        if let data = response.data {
            logMessage += "\nSize: \(data.count) bytes"
            if shouldLogBodies, let rawString = String(data: data, encoding: .utf8) {
                logMessage += "\nRaw Response: \(rawString)"
            }
        }
        
        AppLogger.debug(logMessage, category: .network)
    }
    
    func logResponse(_ response: AFDataResponse<Data?>) {
        var logMessage = "Response:\nStatus: \(String(describing: response.response?.statusCode))\nHeaders: \(String(describing: response.response?.headers))"
        
        if let data = response.data {
            logMessage += "\nSize: \(data.count) bytes"
            if shouldLogBodies, let rawString = String(data: data, encoding: .utf8) {
                logMessage += "\nRaw Response: \(rawString)"
            }
        }
        
        AppLogger.debug(logMessage, category: .network)
    }
}
