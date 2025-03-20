import Foundation

/// Examples demonstrating correct usage of the AppLogger with privacy features
struct LoggingExamples {
    // MARK: - Basic Logging Examples
    
    func basicLoggingExamples() {
        // Standard log levels
        AppLogger.debug("This is a debug message", category: .general)
        AppLogger.info("This is an info message", category: .general)
        AppLogger.warning("This is a warning message", category: .general)
        AppLogger.error("This is an error message", category: .general)
        AppLogger.fault("This is a critical fault message", category: .general)
        
        // Different categories
        AppLogger.info("API endpoint called", category: .network)
        AppLogger.info("User authenticated", category: .auth)
        AppLogger.info("Button tapped", category: .ui)
        AppLogger.info("Database updated", category: .data)
    }
    
    // MARK: - Privacy Handling Examples
    
    func privacyLoggingExamples() {
        // Example sensitive data
        let userId = "u123456789"
        let email = "user@example.com"
        let apiKey = "abcdef1234567890"
        let creditCard = "4111111111111111"
        let userDetails = "Name: John Doe, Age: 30, Location: New York"
        
        // Privacy examples
        AppLogger.info("User ID: \(userId.logMasked())", category: .auth)
        // Output: User ID: *****6789
        
        AppLogger.info("Email: \(email.logPrivate())", category: .auth)
        // Output: Email: <private>
        
        AppLogger.info("API Key: \(apiKey.logMasked())", category: .network)
        // Output: API Key: ********7890
        
        AppLogger.info("Credit Card: \(creditCard.logMasked())", category: .data)
        // Output: Credit Card: ************1111
        
        AppLogger.info("User Details: \(userDetails.logSensitive())", category: .data)
        // Debug Output: User Details: N...(41 chars)
        // Release Output: User Details: <sensitive data>
        
        // Reference data that can be public
        let appVersion = "1.2.3"
        let deviceModel = "iPhone 14 Pro"
        
        AppLogger.info("App Version: \(appVersion.logPublic())", category: .general)
        // Output: App Version: 1.2.3
        
        AppLogger.info("Device Model: \(deviceModel.logPublic())", category: .general)
        // Output: Device Model: iPhone 14 Pro
    }
    
    // MARK: - Network Logging Examples
    
    func networkLoggingExamples() {
        // Example URL and headers
        let url = URL(string: "https://api.example.com/users")!
        let headers = ["Content-Type": "application/json", 
                       "Authorization": "Bearer \("token123456".logPrivate())"]
        
        // Request logging
        AppLogger.info("Sending request to \(url.absoluteString)", category: .network)
        AppLogger.debug("Headers: \(headers)", category: .network)
        
        // Response logging
        AppLogger.info("Received response with status: 200", category: .network)
        
        // Error logging
        let errorMessage = "Network connection timeout"
        AppLogger.error("Request failed: \(errorMessage)", category: .network)
        
        // Using specialized network logging methods
        AppLogger.request(url: url, method: "GET", headers: headers)
        AppLogger.response(url: url, statusCode: 200)
    }
} 