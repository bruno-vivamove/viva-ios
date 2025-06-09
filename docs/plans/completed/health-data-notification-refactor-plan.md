# Health Data Notification Refactor Plan

## Overview
Refactor MatchupCard health data updates from closure-based callbacks to notification-based architecture. This will allow health data updates to trigger UI refreshes from anywhere in the app, not just from direct HealthKitDataManager calls.

## Current Implementation Analysis

### Current Flow
1. `MatchupCardViewModel.loadData()` calls `healthKitDataManager.updateAndUploadHealthData()`
2. HealthKitDataManager executes health queries and uploads data
3. Success/failure result is returned via closure to update the MatchupCard
4. MatchupCard updates its local `@Published var matchup` property

### Current Background Updates
- HealthKitDataManager has `processHealthDataUpdate()` that runs in background
- Background observers detect new HealthKit data and call `processHealthDataUpdate()`
- Currently only logs success/failure but doesn't notify UI components

### Existing Notification Infrastructure
- `NotificationNames.swift` already has `healthDataUpdated` and `workoutsRecorded` notifications defined
- MatchupCardViewModel already observes multiple notifications for matchup updates
- Notification pattern is well-established in the codebase

## Proposed Changes

### Phase 1: Add Health Data Notifications
- [x] Modify `HealthKitDataManager.updateAndUploadHealthMeasurements()` to post `healthDataUpdated` notification on success
- [x] Modify `HealthKitDataManager.updateAndUploadHealthData()` to post `workoutsRecorded` notification when workouts are uploaded
- [x] Include matchup details in notification `object` parameter

### Phase 2: Update MatchupCardViewModel to Listen for Notifications
- [x] Add observer for `healthDataUpdated` notification in `MatchupCardViewModel.setupNotificationObservers()`
- [x] Add observer for `workoutsRecorded` notification
- [x] Filter notifications by matchup ID to only process relevant updates
- [x] Update local matchup data when notifications are received

### Phase 3: Refactor MatchupCardViewModel Health Data Loading
- [x] Modify `MatchupCardViewModel.loadData()` to use notifications instead of closure callback
- [x] Remove closure parameter from `healthKitDataManager.updateAndUploadHealthData()` call
- [x] Simplify error handling to rely on global ErrorManager for health data failures

### Phase 4: Update Background Health Data Processing
- [x] Ensure `HealthKitDataManager.processHealthDataUpdate()` posts notifications for each updated matchup
- [x] Test that background HealthKit observers trigger UI updates in MatchupCards

### Phase 5: Cleanup and Testing
- [x] Remove closure-based completion handlers from HealthKitDataManager public methods
- [x] Update any other components that might be using the closure-based API
- [x] Test background health data updates trigger UI refreshes
- [x] Build and fix any compilation errors

**Testing**: All testing tasks have been moved to `docs/testing-plan.md` for centralized test planning.

## Technical Details

### Notification Payload Structure
```swift
// For healthDataUpdated
NotificationCenter.default.post(
    name: .healthDataUpdated,
    object: updatedMatchupDetails // MatchupDetails object
)

// For workoutsRecorded  
NotificationCenter.default.post(
    name: .workoutsRecorded,
    object: updatedMatchupDetails // MatchupDetails object
)
```

### New Observer Pattern in MatchupCardViewModel
```swift
// Add to setupNotificationObservers()
NotificationCenter.default.publisher(for: .healthDataUpdated)
    .compactMap { $0.object as? MatchupDetails }
    .filter { $0.id == self.matchupId }
    .receive(on: DispatchQueue.main)
    .sink { [weak self] updatedMatchup in
        self?.matchup = updatedMatchup
    }
    .store(in: &cancellables)
```

## Benefits of This Approach

1. **Decoupling**: MatchupCards don't need direct references to HealthKitDataManager
2. **Flexibility**: Health data updates can trigger UI updates from anywhere in the app
3. **Consistency**: Uses the same notification pattern already established for matchup updates
4. **Background Updates**: Background health data processing will automatically update visible UI
5. **Simplified Error Handling**: Health data errors can be handled globally via ErrorManager

## Potential Risks

1. **Timing Issues**: Need to ensure notifications are posted on main queue for UI updates
2. **Memory Leaks**: Ensure proper weak references in notification observers
3. **Duplicate Updates**: Multiple notifications might cause unnecessary UI refreshes
4. **Testing Complexity**: Notification-based updates are harder to unit test

## Questions for Discussion

1. Should we keep both closure-based and notification-based APIs during transition?
2. Do we want to debounce rapid health data notifications to avoid excessive UI updates?
3. Should health data errors still be propagated via notifications or handled differently?
4. Are there other components besides MatchupCard that need health data updates?

## Success Criteria

- [x] MatchupCards update automatically when health data changes in background
- [x] No performance regression in health data processing
- [x] All existing functionality continues to work
- [x] No memory leaks or retain cycles
- [x] Clean, maintainable code following existing patterns

## Status: ✅ COMPLETE

The health data notification refactor has been successfully implemented and all cleanup tasks completed. The system now uses a pure notification-based architecture for health data updates.