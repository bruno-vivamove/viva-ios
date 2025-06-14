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
    
    deinit {
        // Ensure timer is cleaned up when ErrorManager is deallocated
        stopConnectivityMonitoring()
    }
    
    func setHealthService(_ service: HealthService) {
        self.healthService = service
    }
    
    func registerError(_ message: String, type: ErrorType) {
        // Ensure UI updates happen on the main thread
        DispatchQueue.main.async {
            self.currentErrors[type] = message
            
            if type == .network {
                self.startConnectivityMonitoring()
            }
        }
    }
    
    func clearError(type: ErrorType) {
        // Ensure UI updates happen on the main thread
        DispatchQueue.main.async {
            self.currentErrors.removeValue(forKey: type)
            
            if type == .network {
                self.stopConnectivityMonitoring()
            }
        }
    }
    
    func clearAllErrors() {
        // Ensure UI updates happen on the main thread
        DispatchQueue.main.async {
            self.currentErrors.removeAll()
            self.stopConnectivityMonitoring()
        }
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
