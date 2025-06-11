import Foundation
import UIKit

struct DeviceTokenRequest: Codable {
    let deviceToken: String
    let platform: String
    let deviceName: String?
    
    init(deviceToken: String, platform: Platform, deviceName: String? = nil) {
        self.deviceToken = deviceToken
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
    static func ios(deviceToken: String, includeDeviceName: Bool = true) -> DeviceTokenRequest {
        let deviceName = includeDeviceName ? UIDevice.current.name : nil
        return DeviceTokenRequest(
            deviceToken: deviceToken,
            platform: .ios,
            deviceName: deviceName
        )
    }
    
    /// Validates the device token format and requirements
    var isValid: Bool {
        // Check token is not empty and within length limits
        guard !deviceToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              deviceToken.count <= 255 else {
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