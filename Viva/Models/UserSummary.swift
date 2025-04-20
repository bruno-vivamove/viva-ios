import Foundation

struct UserSummaryDto: Codable, Identifiable, Equatable {
    let id: String
    let displayName: String
    let caption: String?
    let imageUrl: String?
    let friendStatus: FriendStatus?
}

struct UserSummaryResponse: Codable {
    let userSummary: UserSummaryDto
} 
