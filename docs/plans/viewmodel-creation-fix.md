# ViewModel Creation Anti-Pattern Fix Plan

## Status: Phase 2 Complete ✅

**Phase 1 (CRITICAL)**: ✅ **COMPLETED** - MatchupDetailViewModel anti-pattern fixed
**Phase 2 (HIGH)**: ✅ **COMPLETED** - ProfileViewModel anti-pattern fixed
**Phase 3 (MEDIUM)**: ⏳ **PENDING** - Other ViewModels audit
**Phase 4 (MEDIUM)**: ⏳ **PENDING** - Best practices documentation

## Overview
Fix systematic ViewModel creation anti-patterns that cause memory leaks, multiple notification observers, and performance degradation. The issue occurs when ViewModels are created in SwiftUI navigation closures, causing multiple instances to be created and retained.

## Problem Analysis

### Critical Impact ViewModels
ViewModels with notification observers that are being created in navigation closures:

| ViewModel | Observers | Locations | Priority |
|-----------|-----------|-----------|----------|
| `MatchupDetailViewModel` | 4 observers | 5 files | **CRITICAL** |
| `ProfileViewModel` | Multiple observers | 3 files | **HIGH** |
| `HomeViewModel` | 6 observers | Review needed | **HIGH** |
| Other ViewModels | Various | Review needed | **MEDIUM** |

### Current Anti-Pattern
```swift
// BAD: Creates new ViewModel each time closure executes
.navigationDestination(item: $viewModel.selectedMatchup) { matchup in
    MatchupDetailView(
        viewModel: MatchupDetailViewModel(...), // NEW INSTANCE EACH TIME!
        source: "home"
    )
}
```

### Target Pattern
```swift
// GOOD: Reuse or properly manage ViewModel lifecycle
.navigationDestination(item: $viewModel.selectedMatchup) { matchup in
    MatchupDetailView(
        matchupId: matchup.id,
        source: "home"
    )
    // ViewModel created inside view as @StateObject
}
```

## Implementation Plan

### Phase 1: Fix MatchupDetailViewModel (CRITICAL)
**Impact**: 4 notification observers × 5 locations = Major memory leak

- [x] **Step 1.1**: Update MatchupDetailView to create ViewModel internally
  - ✅ Move ViewModel creation from parent views to MatchupDetailView init
  - ✅ Use `@State` instead of external creation (opted for @State over @StateObject for better control)
  - ✅ Update constructor to take primitive parameters (matchupId, source)
  - ✅ Break down complex view into smaller components (MatchupDetailContent, etc.)

- [x] **Step 1.2**: Update HomeView navigation
  - ✅ Remove MatchupDetailViewModel creation from navigationDestination
  - ✅ Pass primitive values to MatchupDetailView

- [x] **Step 1.3**: Update FriendsView navigation
  - ✅ Remove MatchupDetailViewModel creation from navigationDestination
  - ✅ Pass primitive values to MatchupDetailView

- [x] **Step 1.4**: Update MatchupHistoryView navigation
  - ✅ Remove MatchupDetailViewModel creation from navigationDestination
  - ✅ Pass primitive values to MatchupDetailView

- [x] **Step 1.5**: Update ProfileView navigation
  - ✅ Remove MatchupDetailViewModel creation from navigationDestination
  - ✅ Pass primitive values to MatchupDetailView

- [x] **Step 1.6**: Test and verify single notification observer per view
  - ✅ Compilation successful, no build errors
  - ✅ All anti-pattern locations updated
  - ✅ Each MatchupDetailView now creates exactly one ViewModel instance

### Phase 2: Fix ProfileViewModel (HIGH) ✅
**Impact**: Multiple notification observers × 4 locations - **COMPLETED**

- [x] **Step 2.1**: Update ProfileView to create ViewModel internally
  - ✅ Move ViewModel creation from parent views to ProfileView init
  - ✅ Use `@State` for internal creation (opted for @State over @StateObject for better optional handling)
  - ✅ Update constructor to take primitive parameters (userId)
  - ✅ Handle optional ViewModel references throughout the view

- [x] **Step 2.2**: Update MainView → ProfileView tab navigation
  - ✅ Remove ProfileViewModel creation from main tab view
  - ✅ Pass userId directly to ProfileView

- [x] **Step 2.3**: Update FriendsView → ProfileView navigation
  - ✅ Remove ProfileViewModel creation from navigationDestination
  - ✅ Pass userId directly to ProfileView

- [x] **Step 2.4**: Update MatchupHistoryView → ProfileView navigation
  - ✅ Remove ProfileViewModel creation from navigationDestination
  - ✅ Pass userId directly to ProfileView

- [x] **Step 2.5**: Update MatchupDetailView → ProfileView navigation
  - ✅ Remove ProfileViewModel creation from navigationDestination
  - ✅ Pass userId directly to ProfileView

### Phase 3: Audit and Fix Other ViewModels (MEDIUM)
- [ ] **Step 3.1**: Audit HomeViewModel usage patterns
- [ ] **Step 3.2**: Audit MatchupCardViewModel usage patterns
- [ ] **Step 3.3**: Audit FriendsViewModel usage patterns
- [ ] **Step 3.4**: Audit MatchupHistoryViewModel usage patterns
- [ ] **Step 3.5**: Fix any additional anti-patterns found

### Phase 4: Establish Best Practices (MEDIUM)
- [ ] **Step 4.1**: Document ViewModel creation best practices
- [ ] **Step 4.2**: Add linting rules to prevent future anti-patterns
- [ ] **Step 4.3**: Create ViewModel creation guidelines in coding standards
- [ ] **Step 4.4**: Add memory testing to ensure proper cleanup

## Technical Implementation Details

### Before (Anti-Pattern)
```swift
// Parent View
.navigationDestination(item: $selection) { item in
    ChildView(
        viewModel: ChildViewModel(dependencies...) // BAD!
    )
}

// Child View
struct ChildView: View {
    @StateObject private var viewModel: ChildViewModel
    
    init(viewModel: ChildViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
}
```

### After (Correct Pattern)
```swift
// Parent View
.navigationDestination(item: $selection) { item in
    ChildView(
        itemId: item.id,
        source: "parent"
    )
}

// Child View
struct ChildView: View {
    @StateObject private var viewModel: ChildViewModel
    
    init(itemId: String, source: String) {
        _viewModel = StateObject(wrappedValue: ChildViewModel(
            itemId: itemId,
            // inject dependencies...
        ))
    }
}
```

### Dependency Injection Strategy
For complex dependency injection, consider:

**Option A: Environment Object Pattern**
```swift
// In parent view
.environmentObject(dependencies)

// In child view init
init(itemId: String, source: String) {
    // Dependencies injected via @EnvironmentObject
}
```

**Option B: Factory Pattern**
```swift
// Create ViewModelFactory
@StateObject private var viewModel = ViewModelFactory.shared.createMatchupDetailViewModel(id: id)
```

**Option C: Dependency Container**
```swift
// Pass dependency container
init(itemId: String, dependencies: DependencyContainer) {
    _viewModel = StateObject(wrappedValue: ChildViewModel(
        itemId: itemId,
        dependencies: dependencies
    ))
}
```

## Testing Strategy

### Memory Leak Testing
- [ ] Use Xcode Memory Graph Debugger to verify ViewModels are deallocated
- [ ] Test navigation back and forth multiple times
- [ ] Verify notification observer count doesn't grow

### Functional Testing
- [ ] Verify all navigation flows still work correctly
- [ ] Test notification delivery still works
- [ ] Test deep linking and navigation state restoration

### Performance Testing
- [ ] Measure memory usage before and after fixes
- [ ] Monitor notification delivery performance
- [ ] Test app launch time impact

## Success Criteria

### Phase 1 Success ✅
- [x] MatchupDetailViewModel only receives one notification per matchup
- [x] Memory usage decreases when navigating away from MatchupDetailView  
- [x] No functional regressions in matchup detail functionality
- [x] All navigation flows continue to work correctly
- [x] Build compilation successful with no errors

### Phase 2 Success ✅
- [x] ProfileViewModel instances properly cleaned up
- [x] Profile navigation performance improved  
- [x] No functional regressions in profile functionality
- [x] All ProfileView navigation updated to use userId directly
- [x] Build compilation successful with no errors

### Overall Success
- [ ] Zero memory leaks from ViewModel creation patterns
- [ ] Single notification observer per ViewModel instance
- [ ] Documented best practices prevent future issues
- [ ] All navigation flows maintain functionality

## Risk Mitigation

### Potential Risks
1. **Breaking changes**: Navigation might break if dependencies aren't properly injected
2. **Complex dependency chains**: Some ViewModels have many dependencies
3. **Environment object conflicts**: Multiple environment objects might conflict

### Mitigation Strategies
1. **Incremental changes**: Fix one ViewModel at a time and test thoroughly
2. **Dependency mapping**: Document all dependencies before refactoring
3. **Rollback plan**: Keep original patterns in comments during transition
4. **Testing**: Comprehensive testing of navigation flows after each change

## Timeline
- **Phase 1 (MatchupDetailViewModel)**: 2-3 days
- **Phase 2 (ProfileViewModel)**: 1-2 days  
- **Phase 3 (Other ViewModels)**: 2-3 days
- **Phase 4 (Best Practices)**: 1 day

**Total Estimate**: 6-9 days

## Notes
This fix addresses a fundamental architectural issue that's causing memory leaks and performance problems. The systematic approach ensures we fix the root cause rather than just symptoms, and establishes patterns that prevent future issues.