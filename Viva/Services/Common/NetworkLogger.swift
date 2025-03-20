import Foundation
import os.log

/// DEPRECATED: Legacy NetworkLogger that forwards to AppLogger
/// This class is maintained for backward compatibility only
/// Please use AppLogger directly instead
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
    
    /// DEPRECATED: Log a message using the legacy format, but forwarding to the new AppLogger
    /// - Parameters:
    ///   - message: The message to log
    ///   - level: The log level
    @available(*, deprecated, message: "Use AppLogger directly instead")
    static func log(message: String, level: LogLevel) {
        // Log deprecation warning in DEBUG mode
        #if DEBUG
        print("⚠️ WARNING: NetworkLogger is deprecated. Please use AppLogger directly instead.")
        #endif
        
        // Forward to new AppLogger while maintaining backward compatibility
        switch level {
        case .debug:
            AppLogger.debug(message, category: .network)
        case .info:
            AppLogger.info(message, category: .network)
        case .error:
            AppLogger.error(message, category: .network)
        }
        
        // Maintain the old debug print behavior for backward compatibility
        #if DEBUG
        debugPrint("\(level.emoji) \(message)")
        #endif
    }
}
