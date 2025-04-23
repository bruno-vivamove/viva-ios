import SwiftUI
import Combine

enum ErrorType {
    case network
    case authentication
    case general
}

class ErrorManager: ObservableObject {
    @Published var currentErrors: [ErrorType: String] = [:]
    
    func displayError(_ message: String, type: ErrorType) {
        currentErrors[type] = message
    }
    
    func clearError(type: ErrorType) {
        currentErrors.removeValue(forKey: type)
    }
    
    func clearAllErrors() {
        currentErrors.removeAll()
    }
    
    var hasErrors: Bool {
        return !currentErrors.isEmpty
    }
} 