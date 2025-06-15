import Foundation

protocol NetworkClientSettings {
    var baseUrl: String { get }
    var headers: [String: String] { get }
    var shouldLogBodies: Bool { get }
    var maxRetries: Int { get }
}

private let defaultMaxRetries = 5

final class AuthNetworkClientSettings: NetworkClientSettings {
    let baseUrl = "https://identitytoolkit.googleapis.com/v1/accounts"
    let headers = [
        "referer": Bundle.main.object(forInfoDictionaryKey: "REFERER") as! String,
    ]
    let shouldLogBodies: Bool
    let maxRetries: Int
    
    init(shouldLogBodies: Bool = false, maxRetries: Int = defaultMaxRetries) {
        self.shouldLogBodies = shouldLogBodies
        self.maxRetries = maxRetries
    }
}

final class AppWithNoSessionNetworkClientSettings: NetworkClientSettings {
    let baseUrl = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as! String
    let headers = [
        "referer": Bundle.main.object(forInfoDictionaryKey: "REFERER") as! String,
    ]
    let shouldLogBodies: Bool
    let maxRetries: Int
    
    init(shouldLogBodies: Bool = false, maxRetries: Int = defaultMaxRetries) {
        self.shouldLogBodies = shouldLogBodies
        self.maxRetries = maxRetries
    }
}

final class AppNetworkClientSettings: NetworkClientSettings {
    let baseUrl = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as! String
    let userSession: UserSession
    let shouldLogBodies: Bool
    let maxRetries: Int
    
    var headers: [String: String]{
        get {
            guard let accessToken = userSession.accessToken else {
                return [:]
            }
            
            return [
                "referer": "https://dev.vivamove.io",
                "Authorization": "Bearer \(accessToken)"
            ]
        }
    }
    
    init(_ userSession: UserSession, shouldLogBodies: Bool = false, maxRetries: Int = defaultMaxRetries) {
        self.userSession = userSession
        self.shouldLogBodies = shouldLogBodies
        self.maxRetries = maxRetries
    }
}
