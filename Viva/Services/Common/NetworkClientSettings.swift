protocol NetworkClientSettings {
    var baseUrl: String { get }
    var headers: [String: String] { get }
}

final class AuthNetworkClientSettings: NetworkClientSettings {
    let baseUrl = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=AIzaSyBt_443_Npn0Rtx-Rk_xBS5CdAt_FqWHh8"
    let headers = [
        "referer": "https://dev.vivamove.io",
    ]
}

final class AppWithNoSessionNetworkClientSettings: NetworkClientSettings {
//    let baseUrl = "https://viva-svc-7e66d6saga-ue.a.run.app"
    let baseUrl = "http://localhost:8080"
    let headers = [
        "referer": "https://dev.vivamove.io",
    ]
}

final class AppNetworkClientSettings: NetworkClientSettings {
//    let baseUrl = "https://viva-svc-7e66d6saga-ue.a.run.app"
    let baseUrl = "http://localhost:8080"
    let userSession: UserSession
    
    var headers: [String: String]{
        get {
            return [
                "referer": "https://dev.vivamove.io",
                "Authorization": "Bearer \(userSession.getAccessToken()!)"
            ]
        }
    }
    
    init(userSession: UserSession) {
        self.userSession = userSession
    }
}
