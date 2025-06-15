import Foundation

struct LogEntry: Codable {
    let level: String
    let message: String
    let timestamp: Date
    let metadata: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case level, message, timestamp, metadata
    }
    
    init(level: String, message: String, timestamp: Date = Date(), metadata: [String: String]? = nil) {
        self.level = level
        self.message = message
        self.timestamp = timestamp
        self.metadata = metadata
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(level, forKey: .level)
        try container.encode(message, forKey: .message)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestampString = formatter.string(from: timestamp)
        try container.encode(timestampString, forKey: .timestamp)
        
        try container.encodeIfPresent(metadata, forKey: .metadata)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        level = try container.decode(String.self, forKey: .level)
        message = try container.decode(String.self, forKey: .message)
        metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata)
        
        let timestampString = try container.decode(String.self, forKey: .timestamp)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: timestampString) {
            timestamp = date
        } else {
            timestamp = Date()
        }
    }
}