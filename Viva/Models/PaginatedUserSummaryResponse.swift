import Foundation

struct PaginatedUserSummaryResponse: Codable {
    let users: [UserSummaryDto]
    let page: Int
    let pageSize: Int
    let totalUsers: Int
} 