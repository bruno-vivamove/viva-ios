# Viva iOS Coding Standards

## Overview
This document establishes coding standards for the Viva iOS project, with special emphasis on SwiftUI ViewModel patterns and architecture best practices.

## Table of Contents
1. [ViewModel Architecture](#viewmodel-architecture)
2. [SwiftUI Best Practices](#swiftui-best-practices)
3. [Memory Management](#memory-management)
4. [Code Organization](#code-organization)
5. [Naming Conventions](#naming-conventions)
6. [Error Handling](#error-handling)
7. [Testing Standards](#testing-standards)
8. [Code Review Guidelines](#code-review-guidelines)

## ViewModel Architecture

### Core Principles
ViewModels are the heart of our SwiftUI architecture. Follow these non-negotiable principles:

#### 1. Lifecycle Management ✅
**ALWAYS use `@StateObject` for ViewModel ownership**

```swift
// ✅ CORRECT
struct MyView: View {
    @StateObject private var viewModel: MyViewModel
    
    init(itemId: String) {
        self._viewModel = StateObject(wrappedValue: MyViewModel(itemId: itemId))
    }
}
```

```swift
// ❌ FORBIDDEN
struct MyView: View {
    @State private var viewModel: MyViewModel?        // Will not update UI
    @ObservedObject var viewModel: MyViewModel       // Memory management issues
}
```

#### 2. Navigation Patterns ✅
**NEVER create ViewModels in navigation closures**

```swift
// ✅ CORRECT
.navigationDestination(item: $selectedItem) { item in
    DetailView(itemId: item.id, source: "navigation")
}

// ❌ FORBIDDEN - Will cause memory leaks
.navigationDestination(item: $selectedItem) { item in
    DetailView(viewModel: DetailViewModel(id: item.id)) // MULTIPLE INSTANCES!
}
```

#### 3. Dependency Injection ✅
**Use one of these approved patterns:**

**Pattern A: Direct Injection**
```swift
struct MyView: View {
    @StateObject private var viewModel: MyViewModel
    
    init(itemId: String, service: MyService, userSession: UserSession) {
        self._viewModel = StateObject(wrappedValue: MyViewModel(
            itemId: itemId,
            service: service,
            userSession: userSession
        ))
    }
}
```

**Pattern B: Environment Objects**
```swift
struct MyView: View {
    @EnvironmentObject var userSession: UserSession
    @EnvironmentObject var myService: MyService
    @StateObject private var viewModel: MyViewModel
    
    var body: some View {
        // Use environment objects in body or onAppear
    }
}
```

### ViewModel Implementation Standards

#### Required Conformance
```swift
class MyViewModel: ObservableObject {
    // ✅ Required: Published properties for UI binding
    @Published var data: [DataModel] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    // ✅ Required: Private dependencies
    private let itemId: String
    private let service: MyService
    private let userSession: UserSession
    
    // ✅ Required: Cancellables for cleanup
    private var cancellables = Set<AnyCancellable>()
    
    // ✅ Required: Proper initialization
    init(itemId: String, service: MyService, userSession: UserSession) {
        self.itemId = itemId
        self.service = service
        self.userSession = userSession
        setupObservers()
    }
    
    // ✅ Required: Cleanup
    deinit {
        cancellables.removeAll()
        print("🗑️ \(String(describing: Self.self)) deallocated") // Debug only
    }
}
```

#### Async Operations Standard
```swift
@MainActor
func loadData() async {
    isLoading = true
    error = nil
    
    do {
        data = try await service.fetchData(itemId: itemId)
    } catch {
        self.error = error
        AppLogger.error("Failed to load data: \(error)", category: .data)
    }
    
    isLoading = false
}
```

## SwiftUI Best Practices

### View Architecture
```swift
struct MyView: View {
    // ✅ Order: StateObject, State, Environment, Bindings
    @StateObject private var viewModel: MyViewModel
    @State private var showingSheet = false
    @EnvironmentObject var userSession: UserSession
    @Binding var isPresented: Bool
    
    // ✅ Private properties after state
    private let itemId: String
    
    // ✅ Init with dependencies
    init(itemId: String, isPresented: Binding<Bool>) {
        self.itemId = itemId
        self._isPresented = isPresented
        self._viewModel = StateObject(wrappedValue: MyViewModel(itemId: itemId))
    }
    
    var body: some View {
        // ✅ Body implementation
    }
}
```

### View Composition Standards
```swift
// ✅ Break down complex views
struct ComplexView: View {
    var body: some View {
        VStack {
            HeaderSection()
            ContentSection()
            FooterSection()
        }
    }
}

// ✅ Extract reusable components
struct HeaderSection: View { /* ... */ }
struct ContentSection: View { /* ... */ }
struct FooterSection: View { /* ... */ }
```

## Memory Management

### Required Practices

#### 1. Weak References in Closures
```swift
// ✅ REQUIRED: Use weak self in async closures
NotificationCenter.default
    .publisher(for: .dataUpdated)
    .sink { [weak self] _ in
        Task { @MainActor in
            await self?.loadData()
        }
    }
    .store(in: &cancellables)
```

#### 2. Cancellable Management
```swift
class MyViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private var currentTask: Task<Void, Never>?
    
    func loadData() {
        currentTask?.cancel()
        currentTask = Task { @MainActor in
            // Async work with cancellation support
        }
    }
    
    deinit {
        currentTask?.cancel()
        cancellables.removeAll()
    }
}
```

#### 3. Debug Memory Deallocation
```swift
// ✅ REQUIRED in debug builds
#if DEBUG
deinit {
    print("🗑️ \(String(describing: Self.self)) deallocated")
}
#endif
```

## Code Organization

### File Structure Standards
```
Views/
├── ComponentName/
│   ├── ComponentView.swift         # Main view
│   ├── ComponentViewModel.swift    # ViewModel
│   └── ComponentSubviews.swift     # Supporting views
└── Shared/
    └── SharedComponents.swift
```

### Naming Conventions

#### ViewModels
```swift
// ✅ REQUIRED naming pattern
class ProfileViewModel: ObservableObject { }      // ViewModel suffix
class MatchupDetailViewModel: ObservableObject { } // Descriptive names
```

#### Views
```swift
// ✅ REQUIRED naming pattern  
struct ProfileView: View { }         // View suffix
struct MatchupDetailView: View { }   // Match ViewModel naming
```

#### Properties
```swift
// ✅ State and binding naming
@State private var isLoading = false          // Clear, descriptive
@StateObject private var viewModel: MyViewModel  // Always viewModel
@Binding var isPresented: Bool               // Clear boolean naming
```

### Import Organization
```swift
// ✅ REQUIRED import order
import SwiftUI          // System frameworks first
import Combine
import Foundation

import Alamofire        // Third-party frameworks
import Lottie

// Internal imports (if any)
```

## Error Handling

### Standard Error Handling Pattern
```swift
// ✅ REQUIRED error handling in ViewModels
@Published var error: Error?

func performAction() async {
    error = nil // Clear previous errors
    
    do {
        let result = try await service.performAction()
        // Handle success
    } catch {
        self.error = error
        AppLogger.error("Action failed: \(error)", category: .network)
    }
}
```

### View Error Display
```swift
// ✅ REQUIRED error display pattern
.alert("Error", isPresented: .constant(viewModel.error != nil)) {
    Button("OK") {
        viewModel.error = nil
    }
} message: {
    if let error = viewModel.error {
        if let vivaError = error as? VivaErrorResponse {
            Text(vivaError.message)
        } else {
            Text(error.localizedDescription)
        }
    }
}
```

## Testing Standards

### ViewModel Testing Requirements
```swift
class MyViewModelTests: XCTestCase {
    
    // ✅ REQUIRED: Test ViewModel deallocation
    func testViewModelDeallocation() {
        weak var weakViewModel: MyViewModel?
        
        do {
            let viewModel = MyViewModel(dependencies...)
            weakViewModel = viewModel
            // Test viewModel usage
        }
        
        XCTAssertNil(weakViewModel, "ViewModel should be deallocated")
    }
    
    // ✅ REQUIRED: Test async operations
    func testAsyncDataLoading() async {
        let viewModel = MyViewModel(dependencies...)
        
        await viewModel.loadData()
        
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.data)
    }
    
    // ✅ REQUIRED: Test error handling
    func testErrorHandling() async {
        let mockService = MockService(shouldFail: true)
        let viewModel = MyViewModel(service: mockService)
        
        await viewModel.loadData()
        
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
    }
}
```

### UI Testing Standards
```swift
// ✅ Test navigation doesn't create memory leaks
func testNavigationMemoryUsage() {
    // Navigate multiple times and verify memory usage
    // Use XCTMemoryMetric to measure memory impact
}
```

## Code Review Guidelines

### Required Checks ✅

**ViewModel Patterns:**
- [ ] Uses @StateObject for ViewModel lifecycle
- [ ] No ViewModel creation in navigation closures
- [ ] Proper dependency injection pattern
- [ ] ObservableObject conformance
- [ ] Async operations use @MainActor

**Memory Management:**
- [ ] Weak references in closures
- [ ] Cancellables properly managed
- [ ] No retain cycles
- [ ] Debug deallocation logging

**SwiftUI Best Practices:**
- [ ] Views broken down into components
- [ ] Proper state management
- [ ] Consistent naming conventions
- [ ] Error handling implemented

**Testing:**
- [ ] ViewModel tests include deallocation tests
- [ ] Async operations tested
- [ ] Error handling tested
- [ ] UI tests for complex flows

### Automatic Checks
The following are enforced by SwiftLint:
- ViewModel creation anti-patterns
- Code style consistency
- Line length and complexity limits
- Naming convention adherence

## Common Anti-Patterns to Avoid ❌

### 1. Multiple ViewModel Instances
```swift
// ❌ FORBIDDEN - Creates multiple instances
.navigationDestination { item in
    DetailView(viewModel: DetailViewModel(item.id))
}
```

### 2. Optional ViewModels
```swift
// ❌ AVOID - Adds complexity
@State private var viewModel: MyViewModel?
```

### 3. Missing Error Handling
```swift
// ❌ FORBIDDEN - No error handling
func loadData() async {
    data = try! await service.fetchData() // Will crash!
}
```

### 4. Retain Cycles
```swift
// ❌ FORBIDDEN - Retain cycle
service.onUpdate = { data in
    self.data = data // Use [weak self]
}
```

## Migration Guidelines

### Adopting These Standards

**Step 1: Audit Existing Code**
- Run SwiftLint to identify violations
- Use Memory Graph Debugger to find leaks
- Review all ViewModel usage patterns

**Step 2: Gradual Migration**
- Fix critical anti-patterns first
- Update ViewModels one at a time
- Add tests as you migrate

**Step 3: Team Training**
- Share this document with all developers
- Include standards in onboarding
- Regular code review focus on patterns

## Enforcement

### Automated (SwiftLint)
- Custom rules prevent ViewModel anti-patterns
- Standard Swift style enforcement
- Integrated into build process

### Code Review
- All PRs require review against these standards
- Focus on ViewModel patterns and memory management
- Reviewer must verify testing requirements

### Continuous Improvement
- Regular review of standards effectiveness
- Update based on new Swift/SwiftUI features
- Team feedback and iteration

## Success Metrics

Following these standards should result in:
- Zero memory leaks from ViewModel patterns
- Consistent app performance
- Faster development and debugging
- Easier code maintenance and reviews
- Higher code quality scores

## Resources

- [SwiftUI ViewModel Best Practices](./swiftui-viewmodel-best-practices.md)
- [SwiftLint Setup Guide](./swiftlint-setup.md)
- [ViewModel Anti-Pattern Fix Plan](./plans/viewmodel-creation-fix.md)
- [Apple SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)

---

**Document Version**: 1.0  
**Last Updated**: Based on ViewModel anti-pattern audit completion  
**Next Review**: After next major SwiftUI update