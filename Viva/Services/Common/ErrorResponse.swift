struct VivaErrorResponse: Codable & Error {
    let code: String
    let message: String
}
