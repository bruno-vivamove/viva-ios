struct PaginatedUserResponse: Codable {
    let users: [User]
    let page: Int
    let pageSize: Int
    let totalUsers: Int
}
