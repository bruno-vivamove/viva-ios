struct ErrorResponse: Codable & Error {
    let code: String
    let message: String
}
