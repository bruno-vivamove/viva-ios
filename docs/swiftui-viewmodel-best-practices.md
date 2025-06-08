# SwiftUI ViewModel Best Practices

## Overview
This document establishes best practices for ViewModel creation and lifecycle management in SwiftUI applications, based on lessons learned from fixing critical memory leaks and performance issues in the Viva iOS app.

## Core Principles

### 1. ViewModel Lifecycle Management
**Always use `@StateObject` for ViewModel ownership and lifecycle management**

```swift
// ✅ CORRECT: @StateObject manages ViewModel lifecycle
struct MyView: View {
    @StateObject private var viewModel: MyViewModel
    
    init(itemId: String, dependencies: Dependencies) {
        self._viewModel = StateObject(wrappedValue: MyViewModel(
            itemId: itemId,
            dependencies: dependencies
        ))
    }
}
```

```swift
// ❌ WRONG: @ObservedObject doesn't manage lifecycle
struct MyView: View {
    @ObservedObject var viewModel: MyViewModel // Memory leaks!
}
```

### 2. Dependency Injection
**Pass primitive values and dependencies to Views, create ViewModels internally**

```swift
// ✅ CORRECT: Pass primitives, create ViewModel inside View
.navigationDestination(item: $selectedItem) { item in
    DetailView(
        itemId: item.id,
        source: "home"
    )
}

// DetailView creates its own ViewModel
struct DetailView: View {
    @StateObject private var viewModel: DetailViewModel
    
    init(itemId: String, source: String) {
        self._viewModel = StateObject(wrappedValue: DetailViewModel(
            itemId: itemId,
            // Inject dependencies via @EnvironmentObject or parameters
            matchupService: matchupService,
            userSession: userSession
        ))
    }
}
```

```swift
// ❌ WRONG: Creating ViewModel in navigation closure
.navigationDestination(item: $selectedItem) { item in
    DetailView(
        viewModel: DetailViewModel(itemId: item.id) // Multiple instances!
    )
}
```

## Anti-Patterns to Avoid

### 1. ViewModel Creation in Navigation Closures
**Problem**: Creates new ViewModel instances every time the closure executes

```swift
// ❌ ANTI-PATTERN: Multiple ViewModel instances
.navigationDestination(item: $selection) { item in
    ChildView(
        viewModel: ChildViewModel(dependencies...) // NEW INSTANCE EACH TIME!
    )
}
```

**Impact**:
- Memory leaks from unreleased ViewModels
- Multiple notification observers
- Performance degradation
- Inconsistent state

### 2. Using @State for ObservableObject ViewModels
**Problem**: @State doesn't properly manage ObservableObject lifecycle

```swift
// ❌ ANTI-PATTERN: @State with ObservableObject
struct MyView: View {
    @State private var viewModel: MyViewModel? // UI won't update!
}
```

**Impact**:
- UI doesn't update when ViewModel @Published properties change
- ViewModel lifecycle not managed by SwiftUI
- Potential retain cycles

### 3. Optional ViewModels with Complex Logic
**Problem**: Optional ViewModels require defensive programming throughout the view

```swift
// ❌ ANTI-PATTERN: Optional ViewModel
@State private var viewModel: MyViewModel?

var body: some View {
    Group {
        if let viewModel = viewModel {
            // Complex conditional logic everywhere
            viewModel.someProperty ?? "default"
        }
    }
}
```

## Recommended Patterns

### Pattern 1: Environment Object Dependencies
For complex dependency injection, use Environment Objects:

```swift
// In parent view
MyChildView(itemId: item.id)
    .environmentObject(userSession)
    .environmentObject(matchupService)

// In child view
struct MyChildView: View {
    @EnvironmentObject var userSession: UserSession
    @EnvironmentObject var matchupService: MatchupService
    @StateObject private var viewModel: MyViewModel
    
    init(itemId: String) {
        // Dependencies injected via @EnvironmentObject in body
    }
    
    var body: some View {
        // Create ViewModel here with environment dependencies
        .onAppear {
            if viewModel == nil {
                viewModel = MyViewModel(
                    itemId: itemId,
                    userSession: userSession,
                    matchupService: matchupService
                )
            }
        }
    }
}
```

### Pattern 2: Direct Dependency Injection
For simpler cases, pass dependencies directly:

```swift
struct MyView: View {
    @StateObject private var viewModel: MyViewModel
    
    init(
        itemId: String,
        userSession: UserSession,
        matchupService: MatchupService
    ) {
        self._viewModel = StateObject(wrappedValue: MyViewModel(
            itemId: itemId,
            userSession: userSession,
            matchupService: matchupService
        ))
    }
}
```

### Pattern 3: Factory Pattern (Advanced)
For very complex dependency graphs:

```swift
struct MyView: View {
    @StateObject private var viewModel: MyViewModel
    
    init(itemId: String) {
        self._viewModel = StateObject(
            wrappedValue: ViewModelFactory.shared.createMyViewModel(itemId: itemId)
        )
    }
}

class ViewModelFactory {
    static let shared = ViewModelFactory()
    
    func createMyViewModel(itemId: String) -> MyViewModel {
        return MyViewModel(
            itemId: itemId,
            dependencies: DependencyContainer.shared
        )
    }
}
```

## ViewModel Implementation Guidelines

### 1. ObservableObject Conformance
```swift
class MyViewModel: ObservableObject {
    @Published var data: [DataModel] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    // Dependencies
    private let itemId: String
    private let service: MyService
    private let userSession: UserSession
    
    // Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    init(itemId: String, service: MyService, userSession: UserSession) {
        self.itemId = itemId
        self.service = service
        self.userSession = userSession
        
        // Setup observers
        setupNotificationObservers()
    }
    
    deinit {
        // Cleanup if needed
        cancellables.removeAll()
    }
}
```

### 2. Notification Observer Management
```swift
private func setupNotificationObservers() {
    NotificationCenter.default
        .publisher(for: .dataUpdated)
        .sink { [weak self] _ in
            Task { @MainActor in
                await self?.loadData()
            }
        }
        .store(in: &cancellables)
}
```

### 3. Async Operations
```swift
@MainActor
func loadData() async {
    isLoading = true
    error = nil
    
    do {
        data = try await service.fetchData(itemId: itemId)
    } catch {
        self.error = error
    }
    
    isLoading = false
}
```

## Testing Strategies

### 1. Memory Leak Testing
```swift
// Use weak references in tests to verify deallocation
weak var weakViewModel: MyViewModel?

func testViewModelDeallocation() {
    do {
        let viewModel = MyViewModel(...)
        weakViewModel = viewModel
        // Use viewModel
    }
    
    // Force deallocation
    XCTAssertNil(weakViewModel, "ViewModel should be deallocated")
}
```

### 2. Notification Observer Testing
```swift
func testSingleNotificationObserver() {
    let expectation = XCTestExpectation(description: "Single notification")
    expectation.expectedFulfillmentCount = 1
    
    let viewModel = MyViewModel(...)
    
    // Post notification that should trigger observer
    NotificationCenter.default.post(name: .dataUpdated, object: nil)
    
    wait(for: [expectation], timeout: 1.0)
}
```

### 3. Integration Testing
```swift
func testNavigationFlow() {
    // Test that navigation works without creating multiple ViewModels
    // Use UI testing to navigate back and forth multiple times
    // Verify memory usage doesn't grow
}
```

## Common Debugging Techniques

### 1. Memory Graph Debugger
- Use Xcode's Memory Graph Debugger to visualize object relationships
- Look for retain cycles and leaked ViewModels
- Check that ViewModels are deallocated when views disappear

### 2. Console Logging
```swift
class MyViewModel: ObservableObject {
    init(...) {
        print("✅ MyViewModel created for item: \(itemId)")
    }
    
    deinit {
        print("🗑️ MyViewModel deallocated for item: \(itemId)")
    }
}
```

### 3. Notification Observer Counting
```swift
// Add this to ViewModels to track observer count
private static var observerCount = 0

private func setupObservers() {
    Self.observerCount += 1
    print("📡 Observer count: \(Self.observerCount)")
    
    // Setup observers...
}

deinit {
    Self.observerCount -= 1
    print("📡 Observer count: \(Self.observerCount)")
}
```

## Performance Best Practices

### 1. Lazy Loading
```swift
class MyViewModel: ObservableObject {
    @Published var data: [DataModel] = []
    private var hasLoadedInitialData = false
    
    func loadInitialDataIfNeeded() async {
        guard !hasLoadedInitialData else { return }
        hasLoadedInitialData = true
        await loadData()
    }
}
```

### 2. Debouncing and Throttling
```swift
@Published var searchText: String = "" {
    didSet {
        debouncedSearch()
    }
}

private func debouncedSearch() {
    searchWorkItem?.cancel()
    searchWorkItem = DispatchWorkItem { [weak self] in
        Task { @MainActor in
            await self?.performSearch()
        }
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: searchWorkItem!)
}
```

### 3. Cancellation Support
```swift
private var currentTask: Task<Void, Never>?

func loadData() {
    currentTask?.cancel()
    currentTask = Task { @MainActor in
        // Async work with cancellation support
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        if Task.isCancelled { return }
        // Continue work...
    }
}
```

## Code Review Checklist

When reviewing SwiftUI ViewModel code, check for:

- [ ] ✅ ViewModels use `@StateObject` for lifecycle management
- [ ] ✅ No ViewModel creation in navigation closures
- [ ] ✅ Dependencies injected via init or Environment Objects
- [ ] ✅ Notification observers properly managed with cancellables
- [ ] ✅ Async operations use `@MainActor` for UI updates
- [ ] ✅ Memory leaks prevented with weak references
- [ ] ✅ ViewModels implement proper cleanup in deinit
- [ ] ✅ No optional ViewModels unless absolutely necessary
- [ ] ✅ UI updates when @Published properties change
- [ ] ✅ Single responsibility principle followed

## Migration Guide

### From Anti-Pattern to Best Practice

**Step 1**: Identify ViewModel creation in navigation closures
```bash
# Search for anti-patterns
grep -r "ViewModel(" --include="*.swift" Views/
```

**Step 2**: Refactor View to create ViewModel internally
```swift
// Before
.navigationDestination { item in
    DetailView(viewModel: DetailViewModel(item.id))
}

// After  
.navigationDestination { item in
    DetailView(itemId: item.id, source: "navigation")
}
```

**Step 3**: Update View init and use @StateObject
```swift
struct DetailView: View {
    @StateObject private var viewModel: DetailViewModel
    
    init(itemId: String, source: String) {
        self._viewModel = StateObject(wrappedValue: DetailViewModel(
            itemId: itemId
        ))
    }
}
```

**Step 4**: Test and verify
- Build succeeds without warnings
- UI updates properly when data changes
- Memory usage doesn't grow during navigation
- Single notification observer per ViewModel

## Conclusion

Following these best practices ensures:
- **Memory Efficiency**: No ViewModel leaks or retain cycles
- **Performance**: Single observers, proper cleanup
- **Maintainability**: Consistent patterns across codebase
- **Scalability**: Easy to add new ViewModels following established patterns
- **Debugging**: Clear lifecycle and ownership model

The patterns established here prevent the memory leaks and performance issues that were resolved in the Viva iOS app ViewModel audit and refactoring project.

## Resources

- [Coding Standards](./coding-standards.md) - Complete coding standards including these ViewModel guidelines
- [SwiftLint Setup Guide](./swiftlint-setup.md) - Automated enforcement of these patterns
- [Memory Testing Guide](./memory-testing-guide.md) - Testing strategies for ViewModel memory management
- [ViewModel Anti-Pattern Fix Plan](./plans/viewmodel-creation-fix.md) - Background on the anti-pattern fixes