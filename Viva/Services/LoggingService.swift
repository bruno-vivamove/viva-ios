import Foundation

final class LoggingService: ObservableObject {
    private let networkClient: NetworkClient<VivaErrorResponse>
    
    init(networkClient: NetworkClient<VivaErrorResponse>) {
        self.networkClient = networkClient
    }
    
    func sendLogEntry(_ logEntry: LogEntry) async {
        do {
            try await networkClient.post(
                path: "/logs",
                body: logEntry
            )
        } catch {
            // Silently handle network failures - we don't want remote logging
            // failures to affect the app's operation or create log spam
            // In debug mode, we can optionally log to console for debugging
            #if DEBUG
            print("Failed to send log to server: \(error)")
            #endif
        }
    }
}