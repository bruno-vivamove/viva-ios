enum NetworkLogger {
    enum LogLevel {
        case debug
        case info
        case error
        
        var emoji: String {
            switch self {
            case .debug: return "🔧"
            case .info: return "ℹ️"
            case .error: return "❌"
            }
        }
    }
    
    static func log(message: String, level: LogLevel) {
        #if DEBUG
        debugPrint("\(level.emoji) \(message)")
        #endif
    }
}
