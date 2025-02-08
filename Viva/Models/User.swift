struct User: Encodable, Decodable, Identifiable {
    let id: String
    let displayName: String
    let imageUrl: String?
}
