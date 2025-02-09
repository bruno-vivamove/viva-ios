import Foundation

@MainActor
class SearchDebouncer {
    private var task: Task<Void, Never>?
    private let delay: TimeInterval
    
    init(delay: TimeInterval = 0.5) {
        self.delay = delay
    }
    
    func debounce(action: @escaping () async -> Void) {
        // Cancel any existing task
        task?.cancel()
        
        // Create a new task with delay
        task = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            // Only execute if task hasn't been cancelled
            if !Task.isCancelled {
                await action()
            }
        }
    }
    
    func cancel() {
        task?.cancel()
        task = nil
    }
}
