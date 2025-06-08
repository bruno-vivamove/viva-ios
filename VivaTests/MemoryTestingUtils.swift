import XCTest
import Combine
@testable import Viva

/// Utility class for testing memory management and ensuring proper ViewModel cleanup
class MemoryTestingUtils {
    
    /// Tests that an object is properly deallocated after going out of scope
    /// - Parameter createObject: Closure that creates the object to test
    /// - Parameter timeout: How long to wait for deallocation (default: 1.0 seconds)
    /// - Returns: True if object was deallocated, false otherwise
    static func testDeallocation<T: AnyObject>(
        timeout: TimeInterval = 1.0,
        createObject: () -> T
    ) -> Bool {
        weak var weakReference: T?
        
        // Create object in isolated scope
        autoreleasepool {
            let object = createObject()
            weakReference = object
            // Object should be retained here
            XCTAssertNotNil(weakReference, "Object should exist while in scope")
        }
        
        // Force garbage collection
        autoreleasepool { }
        
        // Check if object was deallocated
        let expectation = XCTestExpectation(description: "Object deallocation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            if weakReference == nil {
                expectation.fulfill()
            }
        }
        
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout + 0.5)
        return result == .completed
    }
    
    /// Tests ViewModel deallocation with async cleanup
    /// - Parameter createViewModel: Closure that creates the ViewModel
    /// - Parameter performAsyncOperations: Optional closure to perform async operations before testing deallocation
    /// - Parameter timeout: How long to wait for deallocation
    static func testViewModelDeallocation<T: ObservableObject>(
        timeout: TimeInterval = 2.0,
        createViewModel: @escaping () -> T,
        performAsyncOperations: ((T) async -> Void)? = nil
    ) async -> Bool {
        weak var weakViewModel: T?
        
        await autoreleasepool {
            let viewModel = createViewModel()
            weakViewModel = viewModel
            
            // Perform any async operations
            if let performAsyncOperations = performAsyncOperations {
                await performAsyncOperations(viewModel)
            }
            
            XCTAssertNotNil(weakViewModel, "ViewModel should exist while in scope")
        }
        
        // Force cleanup
        await autoreleasepool { }
        
        // Wait for deallocation
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                continuation.resume(returning: weakViewModel == nil)
            }
        }
    }
    
    /// Measures memory usage during a block of code execution
    /// - Parameter operation: The operation to measure
    /// - Returns: Memory usage metrics (approximate)
    static func measureMemoryUsage<T>(operation: () throws -> T) rethrows -> (result: T, memoryIncrease: Int64) {
        let initialMemory = getCurrentMemoryUsage()
        let result = try operation()
        let finalMemory = getCurrentMemoryUsage()
        
        return (result: result, memoryIncrease: finalMemory - initialMemory)
    }
    
    /// Gets current memory usage in bytes (approximate)
    private static func getCurrentMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
    
    /// Tests that notification observers are properly cleaned up
    /// - Parameter createViewModel: Closure that creates a ViewModel with observers
    /// - Parameter triggerNotifications: Closure that triggers notifications the ViewModel observes
    static func testNotificationObserverCleanup<T: ObservableObject>(
        createViewModel: @escaping () -> T,
        triggerNotifications: @escaping () -> Void
    ) async -> Bool {
        weak var weakViewModel: T?
        var notificationReceived = false
        
        // Create ViewModel with observers
        await autoreleasepool {
            let viewModel = createViewModel()
            weakViewModel = viewModel
            
            // Trigger initial notification to ensure observer is working
            triggerNotifications()
            
            // Small delay to ensure notification is processed
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        // Force cleanup
        await autoreleasepool { }
        
        // Wait for ViewModel deallocation
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        let wasDeallOcated = weakViewModel == nil
        
        if wasDeallOcated {
            // Trigger notification after ViewModel should be deallocated
            triggerNotifications()
            
            // If notification observer was properly cleaned up,
            // there should be no crash or memory issues
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        return wasDeallOcated
    }
    
    /// Tests for retain cycles by creating and releasing objects multiple times
    /// - Parameter createObject: Closure that creates the object to test
    /// - Parameter iterations: Number of create/release cycles to test
    static func testRetainCycles<T: AnyObject>(
        createObject: @escaping () -> T,
        iterations: Int = 10
    ) -> Bool {
        var weakReferences: [WeakReference<T>] = []
        
        // Create multiple objects
        for _ in 0..<iterations {
            autoreleasepool {
                let object = createObject()
                weakReferences.append(WeakReference(object))
            }
        }
        
        // Force cleanup
        autoreleasepool { }
        
        // Wait a bit for deallocation
        Thread.sleep(forTimeInterval: 0.5)
        
        // Check that all objects were deallocated
        let deallocatedCount = weakReferences.compactMap { $0.object }.count
        return deallocatedCount == 0
    }
}

/// Helper class to hold weak references for retain cycle testing
private class WeakReference<T: AnyObject> {
    weak var object: T?
    
    init(_ object: T) {
        self.object = object
    }
}

// MARK: - XCTest Extensions

extension XCTestCase {
    
    /// Asserts that an object is properly deallocated
    func assertDeallocation<T: AnyObject>(
        timeout: TimeInterval = 1.0,
        file: StaticString = #filePath,
        line: UInt = #line,
        createObject: () -> T
    ) {
        let wasDeallOcated = MemoryTestingUtils.testDeallocation(
            timeout: timeout,
            createObject: createObject
        )
        
        XCTAssertTrue(
            wasDeallOcated,
            "Object should be deallocated after going out of scope",
            file: file,
            line: line
        )
    }
    
    /// Asserts that a ViewModel is properly deallocated
    func assertViewModelDeallocation<T: ObservableObject>(
        timeout: TimeInterval = 2.0,
        file: StaticString = #filePath,
        line: UInt = #line,
        createViewModel: @escaping () -> T,
        performAsyncOperations: ((T) async -> Void)? = nil
    ) async {
        let wasDeallOcated = await MemoryTestingUtils.testViewModelDeallocation(
            timeout: timeout,
            createViewModel: createViewModel,
            performAsyncOperations: performAsyncOperations
        )
        
        XCTAssertTrue(
            wasDeallOcated,
            "ViewModel should be deallocated after going out of scope",
            file: file,
            line: line
        )
    }
    
    /// Asserts that no retain cycles exist
    func assertNoRetainCycles<T: AnyObject>(
        file: StaticString = #filePath,
        line: UInt = #line,
        createObject: @escaping () -> T,
        iterations: Int = 10
    ) {
        let noRetainCycles = MemoryTestingUtils.testRetainCycles(
            createObject: createObject,
            iterations: iterations
        )
        
        XCTAssertTrue(
            noRetainCycles,
            "Objects should not have retain cycles",
            file: file,
            line: line
        )
    }
}

// MARK: - Performance Testing

extension XCTestCase {
    
    /// Measures memory performance of ViewModel operations
    func measureViewModelMemoryPerformance<T: ObservableObject>(
        name: String,
        createViewModel: @escaping () -> T,
        operation: @escaping (T) async -> Void
    ) async {
        let options = XCTMeasureOptions()
        options.iterationCount = 5
        
        measure(metrics: [XCTMemoryMetric()], options: options) {
            let expectation = XCTestExpectation(description: "Async operation completion")
            
            Task {
                await autoreleasepool {
                    let viewModel = createViewModel()
                    await operation(viewModel)
                }
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
}

// MARK: - Mock Objects for Testing

/// Mock UserSession for testing
class MockUserSession: UserSession {
    override init() {
        super.init()
    }
}

/// Mock services for dependency injection in tests
class MockServices {
    static func createMockMatchupService() -> MatchupService {
        // Return a mock implementation
        return MatchupService(
            networkClient: MockNetworkClient(),
            tokenRefreshHandler: MockTokenRefreshHandler()
        )
    }
    
    static func createMockUserService() -> UserService {
        return UserService(
            networkClient: MockNetworkClient(),
            tokenRefreshHandler: MockTokenRefreshHandler()
        )
    }
}

/// Mock network client for testing
private class MockNetworkClient: NetworkClient<VivaErrorResponse> {
    init() {
        super.init(
            settings: NetworkClientSettings(baseURL: "https://mock.api"),
            tokenRefreshHandler: MockTokenRefreshHandler()
        )
    }
}

/// Mock token refresh handler
private class MockTokenRefreshHandler: TokenRefreshHandler {
    init() {
        super.init(authService: MockAuthService())
    }
}

/// Mock auth service
private class MockAuthService: AuthService {
    init() {
        super.init(
            networkClient: NetworkClient(
                settings: NetworkClientSettings(baseURL: "https://mock.api"),
                tokenRefreshHandler: nil
            )
        )
    }
}