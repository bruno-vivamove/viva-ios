# Memory Testing Guide for ViewModel Cleanup

## Overview
This guide explains how to test for memory leaks and ensure proper ViewModel cleanup in the Viva iOS app. It provides utilities and examples for testing the ViewModel patterns established during the anti-pattern audit.

## Testing Utilities

### MemoryTestingUtils
The `MemoryTestingUtils` class provides static methods for testing memory management:

```swift
// Test basic object deallocation
let wasDeallOcated = MemoryTestingUtils.testDeallocation {
    return MyObject()
}

// Test ViewModel deallocation with async operations
let success = await MemoryTestingUtils.testViewModelDeallocation(
    createViewModel: { MyViewModel() },
    performAsyncOperations: { viewModel in
        await viewModel.loadData()
    }
)

// Test for retain cycles
let noRetainCycles = MemoryTestingUtils.testRetainCycles {
    return MyObject()
}
```

### XCTest Extensions
Convenient assertion methods for common memory testing scenarios:

```swift
class MyViewModelTests: XCTestCase {
    
    func testViewModelMemory() async {
        // Assert ViewModel is properly deallocated
        await assertViewModelDeallocation {
            MyViewModel(dependencies...)
        }
        
        // Assert no retain cycles exist
        assertNoRetainCycles {
            MyViewModel(dependencies...)
        }
    }
}
```

## Required Memory Tests

### 1. Basic ViewModel Deallocation
**Purpose**: Ensure ViewModels are deallocated when no longer referenced

```swift
func testMyViewModelDeallocation() async {
    await assertViewModelDeallocation {
        MyViewModel(
            dependency1: mockDependency1,
            dependency2: mockDependency2
        )
    }
}
```

### 2. ViewModel with Async Operations
**Purpose**: Test that async operations don't prevent deallocation

```swift
func testMyViewModelWithAsyncOps() async {
    await assertViewModelDeallocation(
        createViewModel: { MyViewModel(dependencies...) },
        performAsyncOperations: { viewModel in
            await viewModel.loadData()
            await viewModel.performAction()
            // Wait for operations to complete
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    )
}
```

### 3. Notification Observer Cleanup
**Purpose**: Ensure notification observers are removed when ViewModel is deallocated

```swift
func testNotificationObserverCleanup() async {
    let wasDeallOcated = await MemoryTestingUtils.testNotificationObserverCleanup(
        createViewModel: { MyViewModel(dependencies...) },
        triggerNotifications: {
            NotificationCenter.default.post(
                name: .dataUpdated,
                object: nil
            )
        }
    )
    
    XCTAssertTrue(wasDeallOcated, "ViewModel should clean up observers")
}
```

### 4. Retain Cycle Testing
**Purpose**: Detect retain cycles that prevent deallocation

```swift
func testNoRetainCycles() {
    assertNoRetainCycles(iterations: 10) {
        MyViewModel(dependencies...)
    }
}
```

### 5. Memory Performance Testing
**Purpose**: Measure memory usage to detect memory growth

```swift
func testMemoryPerformance() async {
    await measureViewModelMemoryPerformance(
        name: "MyViewModel Memory Usage",
        createViewModel: { MyViewModel(dependencies...) },
        operation: { viewModel in
            await viewModel.loadData()
            // Perform typical operations
        }
    )
}
```

## Test Examples for Each ViewModel

### ProfileViewModel Tests
```swift
func testProfileViewModelMemory() async {
    await assertViewModelDeallocation {
        ProfileViewModel(
            userId: "test-user-123",
            userSession: MockUserSession(),
            userService: MockServices.createMockUserService(),
            matchupService: MockServices.createMockMatchupService()
        )
    }
}

func testProfileViewModelAsyncOperations() async {
    await assertViewModelDeallocation(
        createViewModel: { 
            ProfileViewModel(/* dependencies */)
        },
        performAsyncOperations: { viewModel in
            await viewModel.loadInitialDataIfNeeded()
            // Test image upload doesn't cause retain cycles
            if let testImage = createTestImage() {
                viewModel.saveProfileImage(testImage)
            }
        }
    )
}
```

### MatchupDetailViewModel Tests
```swift
func testMatchupDetailViewModelMemory() async {
    await assertViewModelDeallocation {
        MatchupDetailViewModel(
            matchupId: "test-matchup-123",
            matchupService: mockMatchupService,
            userMeasurementService: mockUserMeasurementService,
            friendService: mockFriendService,
            userService: mockUserService,
            userSession: mockUserSession,
            healthKitDataManager: mockHealthKitDataManager
        )
    }
}

func testMatchupDetailNotificationCleanup() async {
    let wasDeallOcated = await MemoryTestingUtils.testNotificationObserverCleanup(
        createViewModel: { MatchupDetailViewModel(/* deps */) },
        triggerNotifications: {
            // Trigger notifications the ViewModel observes
            NotificationCenter.default.post(name: .healthDataUpdated, object: nil)
            NotificationCenter.default.post(name: .matchupUpdated, object: nil)
        }
    )
    
    XCTAssertTrue(wasDeallOcated)
}
```

## Common Memory Issues to Test For

### 1. Retain Cycles in Closures
**Problem**: Strong references in closures prevent deallocation

```swift
// ❌ This creates a retain cycle
NotificationCenter.default
    .publisher(for: .dataUpdated)
    .sink { _ in
        self.handleUpdate() // Strong reference to self
    }
    .store(in: &cancellables)

// ✅ Use weak self to break the cycle
NotificationCenter.default
    .publisher(for: .dataUpdated)
    .sink { [weak self] _ in
        self?.handleUpdate()
    }
    .store(in: &cancellables)
```

**Test**:
```swift
func testNoRetainCycleInNotificationObserver() {
    assertNoRetainCycles {
        ViewModelWithNotificationObserver()
    }
}
```

### 2. Task References
**Problem**: Long-running tasks can retain ViewModels

```swift
// ❌ Task retains self
private var currentTask: Task<Void, Never>?

func loadData() {
    currentTask = Task {
        let data = await fetchData()
        self.data = data // Retains self
    }
}

// ✅ Use weak self and cancellation
func loadData() {
    currentTask?.cancel()
    currentTask = Task { [weak self] in
        let data = await fetchData()
        await MainActor.run {
            self?.data = data
        }
    }
}
```

**Test**:
```swift
func testTaskCleanup() async {
    await assertViewModelDeallocation(
        createViewModel: { ViewModelWithTasks() },
        performAsyncOperations: { viewModel in
            await viewModel.loadData()
            // Cancel any running tasks
            viewModel.cancelAllTasks()
        }
    )
}
```

### 3. Delegate References
**Problem**: Strong delegate references create cycles

```swift
// ❌ Strong delegate reference
protocol MyDelegate: AnyObject {
    func didUpdate()
}

class MyService {
    var delegate: MyDelegate? // Should be weak
}

// ✅ Weak delegate reference
class MyService {
    weak var delegate: MyDelegate?
}
```

**Test**:
```swift
func testDelegateReferencesDoNotRetain() {
    assertNoRetainCycles {
        let viewModel = ViewModelWithDelegate()
        let service = ServiceWithDelegate()
        service.delegate = viewModel
        return viewModel
    }
}
```

## Integration with Xcode Memory Tools

### Memory Graph Debugger
1. Run your app in Xcode
2. Navigate to the view with the ViewModel
3. Use the Memory Graph Debugger (Debug → View Memory → Memory Graph Debugger)
4. Look for leaked ViewModel instances
5. Check retain cycles in the graph

### Instruments
1. Use the Leaks instrument to detect memory leaks
2. Use the Allocations instrument to track memory growth
3. Profile navigation flows that create/destroy ViewModels
4. Look for memory that doesn't get released

### Console Debugging
Add debug logging to track ViewModel lifecycle:

```swift
class MyViewModel: ObservableObject {
    init() {
        print("✅ \(String(describing: Self.self)) created")
    }
    
    deinit {
        print("🗑️ \(String(describing: Self.self)) deallocated")
    }
}
```

## Automated Testing in CI

### Test Configuration
```swift
// In your test scheme, enable these settings:
// - Enable Address Sanitizer for detecting memory issues
// - Enable Zombie Objects for detecting use-after-free
// - Enable Malloc Stack logging
```

### GitHub Actions Example
```yaml
- name: Run Memory Tests
  run: |
    xcodebuild test \
      -scheme "Viva - Dev (Debug)" \
      -destination "platform=iOS Simulator,name=iPhone 15" \
      -only-testing:VivaTests/ViewModelMemoryTests \
      -enableAddressSanitizer YES
```

## Best Practices for Memory Testing

### 1. Test All ViewModels
Every ViewModel should have memory tests:
- Basic deallocation test
- Async operations test  
- Notification observer cleanup test
- Retain cycle test

### 2. Use Mock Dependencies
Create lightweight mock dependencies to isolate ViewModel testing:

```swift
class MockUserService: UserService {
    // Minimal implementation for testing
}
```

### 3. Test Navigation Patterns
Test the specific navigation patterns that were causing issues:

```swift
func testNavigationDoesNotLeakViewModels() async {
    // Simulate the navigation pattern
    for _ in 0..<10 {
        await autoreleasepool {
            let viewModel = createViewModelForNavigation()
            // Simulate usage
            await viewModel.loadData()
        }
    }
    
    // Verify no accumulation of memory
    await autoreleasepool { }
    // Memory should be stable here
}
```

### 4. Performance Baselines
Establish memory usage baselines:

```swift
func testMemoryBaseline() async {
    let options = XCTMeasureOptions()
    options.iterationCount = 5
    
    measure(metrics: [XCTMemoryMetric()], options: options) {
        // Standard ViewModel operations
    }
}
```

## Troubleshooting Memory Issues

### Common Symptoms
1. **Growing Memory Usage**: Memory increases with navigation
2. **Slow Performance**: App becomes sluggish over time
3. **Crashes**: Out of memory crashes on devices
4. **Multiple Instances**: Same data loaded multiple times

### Debugging Steps
1. Run memory tests to identify which ViewModel is leaking
2. Use Memory Graph Debugger to visualize retain cycles
3. Check notification observers are being removed
4. Verify async tasks are properly cancelled
5. Check delegate references are weak

### Fix Verification
After fixing memory issues:
1. Run all memory tests and ensure they pass
2. Use Instruments to verify memory usage is stable
3. Test navigation flows extensively
4. Monitor memory usage during extended app usage

## Integration with Existing Code

These memory tests complement the other testing strategies:

1. **Unit Tests**: Test ViewModel business logic
2. **Memory Tests**: Test ViewModel lifecycle and cleanup  
3. **UI Tests**: Test user interaction flows
4. **Performance Tests**: Test app performance under load

The memory testing utilities work with the SwiftLint rules and coding standards to ensure comprehensive memory management across the entire codebase.

## Resources

- [SwiftUI ViewModel Best Practices](./swiftui-viewmodel-best-practices.md)
- [Coding Standards](./coding-standards.md)
- [SwiftLint Setup Guide](./swiftlint-setup.md)
- [ViewModel Anti-Pattern Fix Plan](./plans/viewmodel-creation-fix.md)