import Foundation

protocol NetworkClientSettings {
    var baseUrl: String { get }
    var headers: [String: String] { get }
}

final class AuthNetworkClientSettings: NetworkClientSettings {
    let baseUrl = "https://identitytoolkit.googleapis.com/v1/accounts"
    let headers = [
        "referer": "https://dev.vivamove.io",
    ]
}

final class AppWithNoSessionNetworkClientSettings: NetworkClientSettings {
    let baseUrl = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as! String
    let headers = [
        "referer": "https://dev.vivamove.io",
    ]
}

final class AppNetworkClientSettings: NetworkClientSettings {
    let baseUrl = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as! String
    let userSession: UserSession
    
    var headers: [String: String]{
        get {
            return [
                "referer": "https://dev.vivamove.io",
                "Authorization": "Bearer \(userSession.getAccessToken()!)"
            ]
        }
    }
    
    init(_ userSession: UserSession) {
        self.userSession = userSession
    }
}
