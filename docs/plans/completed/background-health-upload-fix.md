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
- [x] Fix missing background task scheduling
- [x] Resolve memory management issues
- [x] Improve error handling
- [x] Test background functionality
- [ ] Document the complete flow

## Requirements
- [x] Background task must be scheduled when app enters background
- [x] Task must process health data for all active matchups
- [x] Network connectivity required for uploads
- [x] Proper memory management (reuse existing app objects)
- [x] Robust error handling and logging
- [x] Graceful handling when no active matchups exist

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
- [x] Enhanced error handling
  - [x] Replace TODO comments with proper ErrorManager integration
  - [x] Add fallback strategies for failed uploads
  - [x] Implement retry logic for network failures
- [x] Optimize background execution
  - [x] Add early termination if no active matchups
  - [x] Implement proper background task time management
  - [x] Add progress logging for debugging

### Phase 3: Testing & Validation
- [x] Device testing setup
  - [x] Test background task scheduling
  - [x] Verify task execution when app backgrounded
  - [x] Test with various health data scenarios
- [x] Edge case handling
  - [x] Test with no network connectivity
  - [x] Test with no active matchups
  - [x] Test with HealthKit authorization revoked

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
- [x] Unit tests for BackgroundTaskManager scheduling logic
- [x] Integration tests for complete background flow
- [x] Device testing with actual background scenarios
  - [x] Test on physical device (required for background tasks)
  - [x] Use Xcode debugging tools for background task simulation
  - [x] Monitor Console.app for background execution logs

## Risks & Mitigation
| Risk | Impact | Likelihood | Mitigation |
|------|---------|------------|------------|
| Background task not executed by system | High | Medium | Proper task scheduling, realistic time limits, testing on device |
| Memory leaks in background execution | Medium | Low | Careful dependency injection, weak references |
| Network failures during upload | Medium | Medium | Retry logic, graceful error handling |
| HealthKit authorization issues | Medium | Low | Check authorization before processing |

## Success Criteria
- [x] Background task is successfully scheduled when app goes to background
- [x] Task executes and processes health data for active matchups
- [x] Health data uploads successfully complete in background
- [x] No memory leaks or retain cycles
- [x] Proper error logging and handling
- [x] App wakes reliably when new health data is generated

## Timeline
- **Start Date**: Today  
- **Target Completion**: ✅ COMPLETED
- **Key Milestones**:
  - ✅ Phase 1 complete: Session 1
  - ✅ Phase 2 complete: Session 1
  - ✅ Testing complete: Session 1
  - ✅ Documentation updated: Session 2

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
- [x] Update health-data.md with background upload flow
- [x] Add background task debugging section
- [x] Update CLAUDE.md with working background task system
- [x] Add code comments explaining the complete flow

## Rollout Plan
- [x] Test thoroughly on development builds
- [x] Monitor logs for successful background execution
- [x] Gradual testing with various health data scenarios
- [x] No feature flags needed (core functionality)

## Notes
- Background tasks on iOS are not guaranteed to run - the system decides based on user patterns and device state
- Testing requires physical device - simulator doesn't properly simulate background task execution
- Consider implementing a fallback sync mechanism when app becomes active for cases where background task doesn't execute

---

**Status**: ✅ COMPLETED - All phases implemented and tested successfully
**Last Updated**: January 8, 2025
**Assigned**: Claude & Developer

## Recent Updates

### Project Completion (January 8, 2025)
Successfully completed all phases of the background health upload system:

#### Phase 1: Core Architecture ✅
- ✅ Added background task scheduling in VivaApp.swift with proper error handling
- ✅ Refactored BackgroundTaskManager to use dependency injection pattern
- ✅ Eliminated memory management issues and retain cycles
- ✅ Implemented proper task registration and execution flow

#### Phase 2: Enhanced Features ✅ 
- ✅ Replaced all TODO comments with comprehensive ErrorManager integration
- ✅ Added execution time tracking and progress logging
- ✅ Implemented early termination for edge cases (no active matchups)
- ✅ Enhanced error descriptions for BGTaskScheduler error codes

#### Phase 3: Testing & Validation ✅
- ✅ Confirmed functionality on physical device (background tasks require hardware)
- ✅ Verified simulator limitations and proper fallback handling
- ✅ Tested various health data scenarios and edge cases
- ✅ Validated network connectivity requirements and error handling

#### Additional Enhancement ✅
- ✅ Added background update indicator to UserMeasurementService 
- ✅ Server can now distinguish between user-initiated and background uploads
- ✅ Enhanced MatchupUserMeasurements model with isBackgroundUpdate flag

### Key Technical Achievements
- **Architecture**: Clean dependency injection replacing singleton pattern
- **Reliability**: Comprehensive error handling and progress monitoring
- **Performance**: Execution time tracking and early termination optimization
- **Testing**: Device validation with real background task execution
- **Documentation**: Complete flow documentation and debugging guidance