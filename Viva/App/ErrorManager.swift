import SwiftUI
import Combine

enum ErrorType {
    case network
    case authentication
    case general
}

class ErrorManager: ObservableObject {
    @Published var currentErrors: [ErrorType: String] = [:]
    
    private var connectivityTimer: Timer?
    private var healthService: HealthService?
    
    func setHealthService(_ service: HealthService) {
        self.healthService = service
    }
    
    func displayError(_ message: String, type: ErrorType) {
        currentErrors[type] = message
        
        if type == .network {
            startConnectivityMonitoring()
        }
    }
    
    func clearError(type: ErrorType) {
        currentErrors.removeValue(forKey: type)
        
        if type == .network {
            stopConnectivityMonitoring()
        }
    }
    
    func clearAllErrors() {
        currentErrors.removeAll()
        stopConnectivityMonitoring()
    }
    
    var hasErrors: Bool {
        return !currentErrors.isEmpty
    }
    
    private func startConnectivityMonitoring() {
        stopConnectivityMonitoring()
        
        connectivityTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkServerConnectivity()
        }
    }
    
    private func stopConnectivityMonitoring() {
        connectivityTimer?.invalidate()
        connectivityTimer = nil
    }
    
    private func checkServerConnectivity() {
        guard let healthService = healthService else { return }
        
        Task {
            do {
                let _ = try await healthService.ping()
                // Successfully connected to server, clear the network error
                await MainActor.run {
                    clearError(type: .network)
                }
            } catch {
                // Server is still unreachable, keep monitoring
            }
        }
    }
} 