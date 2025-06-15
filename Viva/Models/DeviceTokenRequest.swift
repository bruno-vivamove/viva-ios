import Foundation
import UIKit

struct DeviceTokenRequest: Codable {
    let deviceToken: String      // APNS token
    let notificationToken: String // FCM token
    let platform: String
    let deviceName: String?
    
    init(deviceToken: String, notificationToken: String, platform: Platform, deviceName: String? = nil) {
        self.deviceToken = deviceToken
        self.notificationToken = notificationToken
        self.platform = platform.rawValue
        self.deviceName = deviceName
    }
    
    enum Platform: String, CaseIterable {
        case ios = "ios"
        case android = "android"
    }
}

extension DeviceTokenRequest {
    /// Creates a device token request for iOS with the current device name
    static func ios(deviceToken: String, notificationToken: String, includeDeviceName: Bool = true) -> DeviceTokenRequest {
        let deviceName = includeDeviceName ? UIDevice.current.name : nil
        return DeviceTokenRequest(
            deviceToken: deviceToken,
            notificationToken: notificationToken,
            platform: .ios,
            deviceName: deviceName
        )
    }
    
    /// Validates the device token format and requirements
    var isValid: Bool {
        // Check APNS token is not empty and within length limits
        guard !deviceToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              deviceToken.count <= 255 else {
            return false
        }
        
        // Check FCM token is not empty and within length limits
        guard !notificationToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              notificationToken.count <= 255 else {
            return false
        }
        
        // Check platform is valid
        guard Platform.allCases.map(\.rawValue).contains(platform) else {
            return false
        }
        
        // Check device name length if provided
        if let deviceName = deviceName {
            guard deviceName.count <= 100 else {
                return false
            }
        }
        
        return true
    }
}