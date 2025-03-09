import Foundation
import SwiftUI

final class UserProfileService: ObservableObject {
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
        return try await networkClient.get(path: "/viva/me")
    }

    func saveCurrentUserProfile(
        _ updateRequest: UserProfileUpdateRequest? = nil,
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
                    name: "userProfileUpdateRequest",
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
            path: "/viva/me",
            headers: nil,
            data: multipartData
        )

        Task { @MainActor in
            userSession.setUserProfile(savedUserProfile)
        }
        
        NotificationCenter.default.post(
            name: .userProfileUpdated,
            object: savedUserProfile
        )
        
        return savedUserProfile
    }
}
