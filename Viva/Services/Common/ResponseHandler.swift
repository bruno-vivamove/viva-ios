import Alamofire
import Foundation

final class ResponseHandler<ErrorType: Decodable & Error> {
    private let decoder: JSONDecoder
    
    init(decoder: JSONDecoder) {
        self.decoder = decoder
    }
    
    func handleError<T>(
        _ error: AFError,
        response: DataResponse<T, AFError>,
        continuation: CheckedContinuation<T, Error>
    ) {
        NetworkLogger.log(message: "Error occurred during request", level: .error)
        NetworkLogger.log(message: "Error description: \(error.localizedDescription)", level: .error)
        
        if let underlyingError = error.underlyingError {
            NetworkLogger.log(message: "Underlying error: \(underlyingError)", level: .error)
        }
        
        if let data = response.data,
           let errorResponse = try? decoder.decode(ErrorType.self, from: data) {
            NetworkLogger.log(message: "Decoded Error Response: \(errorResponse)", level: .error)
            continuation.resume(throwing: errorResponse)
        } else {
            let networkError = NetworkClientError(
                code: "REQUEST_ERROR",
                message: error.localizedDescription
            )
            NetworkLogger.log(message: "Network Error: \(networkError)", level: .error)
            if let data = response.data,
               let rawString = String(data: data, encoding: .utf8) {
                NetworkLogger.log(message: "Raw error response: \(rawString)", level: .error)
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
                    NetworkLogger.log(message: "Request retry after token refresh failed: \(error.localizedDescription)", level: .error)
                    continuation.resume(throwing: error)
                }
            }
        } else {
            // Handle error normally for non-401 errors or when we don't have a refresh handler
            NetworkLogger.log(message: "Error occurred during request", level: .error)
            NetworkLogger.log(message: "Error description: \(error.localizedDescription)", level: .error)
            
            if let underlyingError = error.underlyingError {
                NetworkLogger.log(message: "Underlying error: \(underlyingError)", level: .error)
            }
            
            if let data = response.data,
               let errorResponse = try? decoder.decode(ErrorType.self, from: data) {
                NetworkLogger.log(message: "Decoded Error Response: \(errorResponse)", level: .error)
                continuation.resume(throwing: errorResponse)
            } else {
                let networkError = NetworkClientError(
                    code: "REQUEST_ERROR",
                    message: error.localizedDescription
                )
                NetworkLogger.log(message: "Network Error: \(networkError)", level: .error)
                if let data = response.data,
                   let rawString = String(data: data, encoding: .utf8) {
                    NetworkLogger.log(message: "Raw error response: \(rawString)", level: .error)
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
        NetworkLogger.log(message: "Error occurred during request", level: .error)
        NetworkLogger.log(message: "Error description: \(error.localizedDescription)", level: .error)
        
        if let underlyingError = error.underlyingError {
            NetworkLogger.log(message: "Underlying error: \(underlyingError)", level: .error)
        }
        
        if let data = response.data,
           let errorResponse = try? decoder.decode(ErrorType.self, from: data) {
            NetworkLogger.log(message: "Decoded Error Response: \(errorResponse)", level: .error)
            continuation.resume(throwing: errorResponse)
        } else {
            let networkError = NetworkClientError(
                code: "REQUEST_ERROR",
                message: error.localizedDescription
            )
            NetworkLogger.log(message: "Network Error: \(networkError)", level: .error)
            if let data = response.data,
               let rawString = String(data: data, encoding: .utf8) {
                NetworkLogger.log(message: "Raw error response: \(rawString)", level: .error)
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
                    NetworkLogger.log(message: "Request retry after token refresh failed: \(error.localizedDescription)", level: .error)
                    continuation.resume(throwing: error)
                }
            }
        } else {
            // Handle error normally for non-401 errors or when we don't have a refresh handler
            NetworkLogger.log(message: "Error occurred during request", level: .error)
            NetworkLogger.log(message: "Error description: \(error.localizedDescription)", level: .error)
            
            if let underlyingError = error.underlyingError {
                NetworkLogger.log(message: "Underlying error: \(underlyingError)", level: .error)
            }
            
            if let data = response.data,
               let errorResponse = try? decoder.decode(ErrorType.self, from: data) {
                NetworkLogger.log(message: "Decoded Error Response: \(errorResponse)", level: .error)
                continuation.resume(throwing: errorResponse)
            } else {
                let networkError = NetworkClientError(
                    code: "REQUEST_ERROR",
                    message: error.localizedDescription
                )
                NetworkLogger.log(message: "Network Error: \(networkError)", level: .error)
                if let data = response.data,
                   let rawString = String(data: data, encoding: .utf8) {
                    NetworkLogger.log(message: "Raw error response: \(rawString)", level: .error)
                }
                continuation.resume(throwing: networkError)
            }
        }
    }
    
    func isUnauthorizedError(_ response: HTTPURLResponse?) -> Bool {
        return response?.statusCode == 401
    }
    
    func logResponse<T>(_ response: DataResponse<T, AFError>) {
        NetworkLogger.log(message: "Attempting to decode to type: \(T.self)", level: .debug)
        NetworkLogger.log(message: "Response Status: \(String(describing: response.response?.statusCode))", level: .debug)
        NetworkLogger.log(message: "Response Headers: \(String(describing: response.response?.headers))", level: .debug)
        
        if let data = response.data {
            NetworkLogger.log(message: "Response size: \(data.count) bytes", level: .debug)
            if let rawString = String(data: data, encoding: .utf8) {
                NetworkLogger.log(message: "Raw Response string: \(rawString)", level: .debug)
            }
        }
    }
    
    func logResponse(_ response: AFDataResponse<Data?>) {
        NetworkLogger.log(message: "Response Status: \(String(describing: response.response?.statusCode))", level: .debug)
        NetworkLogger.log(message: "Response Headers: \(String(describing: response.response?.headers))", level: .debug)
        
        if let data = response.data {
            NetworkLogger.log(message: "Response size: \(data.count) bytes", level: .debug)
            if let rawString = String(data: data, encoding: .utf8) {
                NetworkLogger.log(message: "Raw Response string: \(rawString)", level: .debug)
            }
        }
    }
}
