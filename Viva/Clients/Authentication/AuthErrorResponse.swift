struct AuthErrorResponse: Codable & Error{
    let error: ErrorDetails
    
    struct ErrorDetails: Codable {
        let code: Int
        let message: String
        let errors: [ErrorInfo]
        
        struct ErrorInfo: Codable {
            let message: String
            let domain: String
            let reason: String
        }
    }
}
