import Foundation

struct PaginatedUserSummaryResponse: Codable {
    let users: [UserSummary]
    let pagination: PaginationMetadata
}

struct PaginationMetadata: Codable {
    let page: Int
    let pageSize: Int
    let totalItems: Int
    let totalPages: Int
} 
