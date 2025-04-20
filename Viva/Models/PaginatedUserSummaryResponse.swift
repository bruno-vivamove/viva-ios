import Foundation

struct PaginatedUserSummaryResponse: Codable {
    let users: [UserSummary]
    let page: Int
    let pageSize: Int
    let totalUsers: Int
} 
