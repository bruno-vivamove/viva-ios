import Foundation
import SwiftUI

final class UserService: ObservableObject {
    private let networkClient: NetworkClient<VivaErrorResponse>
    private let userSession: UserSession

    init(
        networkClient: NetworkClient<VivaErrorResponse>,
        userSession: UserSession
    ) {
        self.networkClient = networkClient
        self.userSession = userSession
    }

    func getCurrentUserProfile() async throws -> UserProfile {
        return try await networkClient.get(path: "/users/me/profile")
    }
    
    func getUserProfile(userId: String) async throws -> UserProfile {
        return try await networkClient.get(path: "/users/\(userId)/profile")
    }

    func getCurrentUserAccount() async throws -> UserAccountResponse {
        return try await networkClient.get(path: "/users/me/account")
    }

    func saveCurrentUserAccount(
        _ updateRequest: UserAccountUpdateRequest? = nil,
        _ selectedImage: UIImage? = nil
    ) async throws -> UserProfile {
        var multipartData: [MultipartData] = []

        // At least one parameter must be provided
        guard updateRequest != nil || selectedImage != nil else {
            throw NSError(
                domain: "UserProfileService",
                code: 400,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Either profile update data or image must be provided"
                ]
            )
        }

        // Convert profile update request to JSON data if provided
        if let updateRequest = updateRequest {
            let jsonEncoder = JSONEncoder()
            let profileData = try jsonEncoder.encode(updateRequest)
            multipartData.append(
                MultipartData(
                    data: profileData,
                    name: "userAccountUpdateRequest",
                    mimeType: "application/json"
                ))
        }

        // Add image data if provided
        if let image = selectedImage,
            let imageData = image.jpegData(compressionQuality: 0.8)
        {
            multipartData.append(
                MultipartData(
                    data: imageData,
                    name: "profileImageFile",
                    mimeType: "image/jpeg"
                ))
        }

        let savedUserProfile: UserProfile = try await networkClient.upload(
            path: "/users/me/account",
            headers: nil,
            data: multipartData
        )

        NotificationCenter.default.post(
            name: .userProfileUpdated,
            object: savedUserProfile
        )
        
        return savedUserProfile
    }
    
    func searchUsers(query: String, page: Int = 1, pageSize: Int = 20) async throws -> [UserSummary] {
        let response: PaginatedUserSummaryResponse = try await networkClient.get(
            path: "/users/search",
            queryParams: [
                "q": query,
                "page": page,
                "page_size": pageSize
            ]
        )
        return response.users
    }
}
