import Foundation
import SwiftUI

struct UserPreferences: Codable {
    var pushNotificationsEnabled: Bool
    var darkModeEnabled: Bool
    var selectedTheme: String
}

struct AppConfiguration: Codable {
    var serverUrl: String
    var apiVersion: String
    var featureFlags: [String: Bool]
}

// Main app state container
class AppState: ObservableObject {
    @Published var isLoading = false
    @Published var appConfig: AppConfiguration?
    
    public let userSession: UserSession = UserSession()

    @MainActor
    func refreshData() async {
        isLoading = true

        isLoading = false
    }
}

