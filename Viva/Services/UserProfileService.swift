import Foundation
import SwiftUI

final class UserProfileService {
    private let networkClient: NetworkClient
    private let userSession: UserSession

    init(networkClient: NetworkClient, userSession: UserSession) {
        self.networkClient = networkClient
        self.userSession = userSession
    }

    func getCurrentUserProfile() async throws -> UserProfile {
        return try await networkClient.get(path: "/viva/me")
    }

    func saveCurrentUserProfile(
        _ updateRequest: UserProfileUpdateRequest, _ selectedImage: UIImage?
    ) async throws -> UserProfile {
        var multipartData: [NetworkClient.MultipartData] = []

        // Convert profile update request to JSON data
        let jsonEncoder = JSONEncoder()
        let profileData = try jsonEncoder.encode(updateRequest)
        multipartData.append(
            NetworkClient.MultipartData(
                data: profileData,
                name: "userProfileUpdateRequest",
                mimeType: "application/json"
            ))

        // Add image data if provided
        if let image = selectedImage,
            let imageData = image.jpegData(compressionQuality: 0.8)
        {
            multipartData.append(
                NetworkClient.MultipartData(
                    data: imageData,
                    name: "profileImageFile",
                    mimeType: "image/jpeg"
                ))
        }

        return try await networkClient.upload(
            path: "/viva/me",
            headers: nil,
            data: multipartData
        )
    }
}
