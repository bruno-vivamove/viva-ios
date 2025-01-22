struct ClientError: Error {
    let code: String
    let message: String?
    
    init(code: String, message: String? = nil) {
        self.code = code
        self.message = message
    }
}
