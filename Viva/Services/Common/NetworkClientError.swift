struct NetworkClientError: Error {
    let code: String
    let message: String
    
    init(code: String, message: String) {
        self.code = code
        self.message = message
    }
    
    // Factory methods for creating common errors
    static func requestError(message: String) -> NetworkClientError {
        NetworkClientError(code: "REQUEST_ERROR", message: message)
    }
    
    static func connectionError() -> NetworkClientError {
        NetworkClientError(code: "CONNECTION_ERROR", message: "Unable to connect to the server")
    }
    
    static func timeoutError() -> NetworkClientError {
        NetworkClientError(code: "TIMEOUT_ERROR", message: "Request timed out")
    }
    
    static func serverError(message: String = "Internal server error") -> NetworkClientError {
        NetworkClientError(code: "SERVER_ERROR", message: message)
    }
    
    static func authenticationError() -> NetworkClientError {
        NetworkClientError(code: "AUTHENTICATION_ERROR", message: "Authentication failed")
    }

    // Create a more user-friendly message for specific error codes
    var userFriendlyMessage: String {
        switch code {
        case "REQUEST_ERROR":
            return "Unable to connect to the internet"
        case "CONNECTION_ERROR":
            return "Unable to connect to the internet"
        case "TIMEOUT_ERROR":
            return "Unable to connect to the internet"
        case "SERVER_ERROR":
            return "Server error occurred. Our team has been notified"
        case "AUTHENTICATION_ERROR":
            return "Your session has expired. Please log in again"
        default:
            return message
        }
    }
}
