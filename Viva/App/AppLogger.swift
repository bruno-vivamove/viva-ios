import Foundation
import os.log

/// A centralized logging system for the Viva app
struct AppLogger {
    
    // MARK: - Static Properties
    
    /// Static reference to the logging service for remote logging
    private static var loggingService: LoggingService?
    
    /// Configure the AppLogger with a LoggingService instance
    static func configure(with loggingService: LoggingService) {
        AppLogger.loggingService = loggingService
    }
    
    // MARK: - Private Properties
    
    /// Date formatter for consistent timestamp formatting across all logs
    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    /// Log categories to organize logs by app component
    enum Category: String {
        case network = "Network"
        case auth = "Authentication"
        case ui = "UserInterface"
        case data = "DataManagement"
        case general = "General"
        case health = "HealthData"
        
        var logger: Logger {
            Logger(subsystem: Bundle.main.bundleIdentifier!, category: self.rawValue)
        }
    }
    
    /// Log a debug message (only collected during debugging)
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The category for this log
    ///   - file: Source file (auto-filled)
    ///   - function: Function name (auto-filled)
    ///   - line: Line number (auto-filled)
    static func debug(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        let context = extractContext(file: file, function: function, line: line)
        category.logger.debug("[\(context, privacy: .public)]\n\(message, privacy: .public)")
        sendLogRemotely(level: "DEBUG", message: message, category: category, file: file, function: function, line: line)
    }
    
    /// Log an info message (collected but may be dynamically disabled)
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The category for this log
    ///   - file: Source file (auto-filled)
    ///   - function: Function name (auto-filled)
    ///   - line: Line number (auto-filled)
    static func info(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        let context = extractContext(file: file, function: function, line: line)
        category.logger.info("[\(context, privacy: .public)]\n\(message, privacy: .public)")
        sendLogRemotely(level: "INFO", message: message, category: category, file: file, function: function, line: line)
    }
    
    /// Log a default message (standard level for most logging needs)
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The category for this log
    ///   - file: Source file (auto-filled)
    ///   - function: Function name (auto-filled)
    ///   - line: Line number (auto-filled)
    static func log(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        let context = extractContext(file: file, function: function, line: line)
        category.logger.log("[\(context, privacy: .public)]\n\(message, privacy: .public)")
        sendLogRemotely(level: "INFO", message: message, category: category, file: file, function: function, line: line)
    }
    
    /// Log a warning message (default visibility)
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The category for this log
    ///   - file: Source file (auto-filled)
    ///   - function: Function name (auto-filled)
    ///   - line: Line number (auto-filled)
    static func warning(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        let context = extractContext(file: file, function: function, line: line)
        category.logger.warning("[\(context, privacy: .public)]\n\(message, privacy: .public)")
        sendLogRemotely(level: "WARN", message: message, category: category, file: file, function: function, line: line)
    }
    
    /// Log an error message (persisted due to higher importance)
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The category for this log
    ///   - file: Source file (auto-filled)
    ///   - function: Function name (auto-filled)
    ///   - line: Line number (auto-filled)
    static func error(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        let context = extractContext(file: file, function: function, line: line)
        category.logger.error("[\(context, privacy: .public)]\n\(message, privacy: .public)")
        sendLogRemotely(level: "ERROR", message: message, category: category, file: file, function: function, line: line)
    }
    
    /// Log a critical fault (always collected, for severe issues)
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The category for this log
    ///   - file: Source file (auto-filled)
    ///   - function: Function name (auto-filled)
    ///   - line: Line number (auto-filled)
    static func fault(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        let context = extractContext(file: file, function: function, line: line)
        category.logger.fault("[\(context, privacy: .public)]\n\(message, privacy: .public)")
        sendLogRemotely(level: "ERROR", message: message, category: category, file: file, function: function, line: line)
    }
    
    
    
    // MARK: - Helper Methods
    
    /// Extract context information from file, function and line, including timestamp
    private static func extractContext(file: String, function: String, line: Int) -> String {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let timestamp = timestampFormatter.string(from: Date())
        return "\(timestamp) \(fileName):\(line) \(function)"
    }
    
    /// Send log entry to remote server asynchronously
    private static func sendLogRemotely(
        level: String,
        message: String,
        category: Category,
        file: String,
        function: String,
        line: Int
    ) {
        guard let loggingService = loggingService else { return }
        
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let metadata: [String: String] = [
            "category": category.rawValue,
            "file": fileName,
            "function": function,
            "line": String(line)
        ]
        
        let logEntry = LogEntry(
            level: level,
            message: message,
            metadata: metadata
        )
        
        Task {
            await loggingService.sendLogEntry(logEntry)
        }
    }
}

// MARK: - Privacy Extensions

/// Enum defining privacy options for logging
public enum LogPrivacy {
    case `private`
    case `public`
    case masked
    case sensitive
    
    /// Apply privacy settings to a string value
    public func apply(to value: String) -> String {
        switch self {
        case .private:
            return redactValue(value)
        case .public:
            return value
        case .masked:
            return maskValue(value)
        case .sensitive:
            return sensitiveValue(value)
        }
    }
    
    /// Redact a value completely (show as <private>)
    private func redactValue(_ value: String) -> String {
        #if DEBUG
        return "<private>"
        #else
        // In production, we use os_log privacy if available
        #if compiler(>=5.6)
        // Use string interpolation with privacy specifier for OSLog
        return "REDACTED_FOR_PRIVACY" // This will be replaced by the compiler
        #else
        return "<private>"
        #endif
        #endif
    }
    
    /// Mask a value but show the last 4 characters
    private func maskValue(_ value: String) -> String {
        guard value.count > 4 else { return "****" }
        return String(repeating: "*", count: value.count - 4) + value.suffix(4)
    }
    
    /// Handle sensitive data (shows brief info in debug, nothing in production)
    private func sensitiveValue(_ value: String) -> String {
        #if DEBUG
        // In debug, show first character and length
        guard !value.isEmpty else { return "<empty>" }
        return "\(value.prefix(1)...)(\(value.count) chars)"
        #else
        return "<sensitive data>"
        #endif
    }
}

// MARK: - String Extensions for Privacy

extension String {
    /// Log this string as private (fully redacted)
    public func logPrivate() -> String {
        return LogPrivacy.private.apply(to: self)
    }
    
    /// Log this string as public (fully visible)
    public func logPublic() -> String {
        return LogPrivacy.public.apply(to: self)
    }
    
    /// Log this string as masked (showing only last 4 chars)
    public func logMasked() -> String {
        return LogPrivacy.masked.apply(to: self)
    }
    
    /// Log this string as sensitive (brief info in debug, nothing in production)
    public func logSensitive() -> String {
        return LogPrivacy.sensitive.apply(to: self)
    }
}

// MARK: - AppLogger Privacy Logging Methods

extension AppLogger {
    /// Log a message with privacy-handled values
    static func logWithPrivacy(_ message: String, 
                              category: Category = .general, 
                              level: OSLogType = .debug,
                              file: String = #file, 
                              function: String = #function, 
                              line: Int = #line) {
        switch level {
        case .debug:
            debug(message, category: category, file: file, function: function, line: line)
        case .info:
            info(message, category: category, file: file, function: function, line: line)
        case .error:
            error(message, category: category, file: file, function: function, line: line)
        case .fault:
            fault(message, category: category, file: file, function: function, line: line)
        default:
            log(message, category: category, file: file, function: function, line: line)
        }
    }
} 
