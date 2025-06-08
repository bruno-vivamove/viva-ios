# Background Health Data Upload Fix

## Overview
Fix the background health data upload system to ensure that when users generate new health data, the app wakes up in the background and uploads health data for each of the user's active matches. Currently, the infrastructure is in place but the critical task scheduling step is missing.

## Background
The app has a comprehensive background task system with:
- Proper BackgroundTaskManager registration and handling
- HealthKitDataManager with logic to process active matchups
- Correct Info.plist configuration with background modes and task identifiers
- HealthKit background observers for data changes

However, the system is non-functional because **the background task is never actually scheduled** when the app goes to background.

## Goals
- [x] Audit current background task implementation
- [ ] Fix missing background task scheduling
- [ ] Resolve memory management issues
- [ ] Improve error handling
- [ ] Test background functionality
- [ ] Document the complete flow

## Requirements
- [ ] Background task must be scheduled when app enters background
- [ ] Task must process health data for all active matchups
- [ ] Network connectivity required for uploads
- [ ] Proper memory management (reuse existing app objects)
- [ ] Robust error handling and logging
- [ ] Graceful handling when no active matchups exist

## Implementation Plan

### Phase 1: Core Fix
- [x] Add background task scheduling in VivaApp.swift
  - [x] Import BackgroundTasks framework
  - [x] Create BGProcessingTaskRequest in .background case
  - [x] Set requiresNetworkConnectivity = true
  - [x] Add proper error handling for task submission
- [x] Fix memory management in BackgroundTaskManager
  - [x] Pass existing VivaAppObjects instance instead of creating new one
  - [x] Update method signature to accept dependencies
  - [x] Ensure proper cleanup and avoid retain cycles

### Phase 2: Improvements
- [ ] Enhanced error handling
  - [ ] Replace TODO comments with proper ErrorManager integration
  - [ ] Add fallback strategies for failed uploads
  - [ ] Implement retry logic for network failures
- [ ] Optimize background execution
  - [ ] Add early termination if no active matchups
  - [ ] Implement proper background task time management
  - [ ] Add progress logging for debugging

### Phase 3: Testing & Validation
- [ ] Device testing setup
  - [ ] Test background task scheduling
  - [ ] Verify task execution when app backgrounded
  - [ ] Test with various health data scenarios
- [ ] Edge case handling
  - [ ] Test with no network connectivity
  - [ ] Test with no active matchups
  - [ ] Test with HealthKit authorization revoked

## Technical Details

### Architecture Changes
- Modify `VivaApp.swift` to schedule background tasks in scene phase changes
- Update `BackgroundTaskManager` to accept dependency injection
- Improve error handling throughout the background flow

### Dependencies
- **Existing**: BackgroundTasks framework (already imported)
- **Services affected**: 
  - HealthKitDataManager (core functionality)
  - MatchupService (fetching active matchups)
  - UserMeasurementService (uploading measurements)
  - WorkoutService (uploading workouts)

### API Changes
None - using existing service methods.

## Testing Strategy
- [ ] Unit tests for BackgroundTaskManager scheduling logic
- [ ] Integration tests for complete background flow
- [ ] Device testing with actual background scenarios
  - [ ] Test on physical device (required for background tasks)
  - [ ] Use Xcode debugging tools for background task simulation
  - [ ] Monitor Console.app for background execution logs

## Risks & Mitigation
| Risk | Impact | Likelihood | Mitigation |
|------|---------|------------|------------|
| Background task not executed by system | High | Medium | Proper task scheduling, realistic time limits, testing on device |
| Memory leaks in background execution | Medium | Low | Careful dependency injection, weak references |
| Network failures during upload | Medium | Medium | Retry logic, graceful error handling |
| HealthKit authorization issues | Medium | Low | Check authorization before processing |

## Success Criteria
- [ ] Background task is successfully scheduled when app goes to background
- [ ] Task executes and processes health data for active matchups
- [ ] Health data uploads successfully complete in background
- [ ] No memory leaks or retain cycles
- [ ] Proper error logging and handling
- [ ] App wakes reliably when new health data is generated

## Timeline
- **Start Date**: Today
- **Target Completion**: Within 1-2 development sessions
- **Key Milestones**:
  - Phase 1 complete: Next session
  - Testing complete: Following session
  - Documentation updated: Same session as completion

## Code Changes Required

### VivaApp.swift - Add Task Scheduling
```swift
case .background:
    AppLogger.info("App entered background", category: .general)
    
    // Schedule background health update task if user is logged in
    if vivaAppObjects.userSession.isLoggedIn {
        let request = BGProcessingTaskRequest(identifier: BackgroundTaskManager.backgroundHealthUpdateTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
            AppLogger.info("Successfully scheduled background health update task", category: .general)
        } catch {
            AppLogger.error("Failed to schedule background task: \(error)", category: .general)
        }
    }
```

### BackgroundTaskManager.swift - Fix Memory Management
```swift
// Update method signature to accept dependencies
private func handleHealthKitProcessingTask(task: BGProcessingTask, vivaAppObjects: VivaAppObjects) {
    // Use passed instance instead of creating new one
    vivaAppObjects.healthKitDataManager.processHealthDataUpdate()
    // ... rest of implementation
}
```

## Documentation Updates
- [ ] Update health-data.md with background upload flow
- [ ] Add background task debugging section
- [ ] Update CLAUDE.md with working background task system
- [ ] Add code comments explaining the complete flow

## Rollout Plan
- [ ] Test thoroughly on development builds
- [ ] Monitor logs for successful background execution
- [ ] Gradual testing with various health data scenarios
- [ ] No feature flags needed (core functionality)

## Notes
- Background tasks on iOS are not guaranteed to run - the system decides based on user patterns and device state
- Testing requires physical device - simulator doesn't properly simulate background task execution
- Consider implementing a fallback sync mechanism when app becomes active for cases where background task doesn't execute

---

**Status**: Phase 1 Complete - Core functionality implemented with proper architecture
**Last Updated**: January 8, 2025
**Assigned**: Claude & Developer

## Recent Updates

### Architecture Refactor (January 8, 2025)
Successfully refactored BackgroundTaskManager to follow proper dependency injection:
- ✅ Removed singleton pattern in favor of dependency injection
- ✅ BackgroundTaskManager now instantiated in VivaAppObjects with proper dependencies
- ✅ Only VivaApp maintains reference to VivaAppObjects (clean architecture)
- ✅ BackgroundTaskManager receives HealthKitDataManager via constructor
- ✅ All builds passing, ready for Phase 2 or testing