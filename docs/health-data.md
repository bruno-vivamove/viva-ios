# Health Data Architecture

This document provides a comprehensive overview of how the Viva iOS app integrates with HealthKit to collect, process, and use health data for fitness competitions.

## Overview

The Viva app uses Apple's HealthKit framework to collect user health and fitness data for competitive matchups between friends. The system is designed to be privacy-first, performant, and accurate while providing real-time updates for ongoing competitions.

## Core Components

### 1. HealthKitDataManager
**Location**: `/Viva/HealthData/HealthKitDataManager.swift`

The central orchestrator for all health data operations.

**Key Responsibilities:**
- Manages HealthKit authorization and permissions
- Coordinates health data queries for matchups
- Uploads measurement data to the backend
- Handles background health data observers
- Posts notifications for UI updates

**Architecture:**
```swift
final class HealthKitDataManager: ObservableObject {
    private let healthStore = HKHealthStore()
    private var queryHandlers: [MeasurementType: HealthDataQuery] = [:]
    private var backgroundObservers: [HKObserverQuery] = []
    @Published var isAuthorized = false
}
```

### 2. Health Data Query System

**Base Protocol**: `HealthDataQuery`
- Defines interface for health data query operations
- Standardizes the query execution pattern

**Base Implementation**: `BaseHealthQuery`
- Provides common query functionality
- Handles day-based time calculations
- Manages HealthKit store access

**Specialized Query Classes:**
- `StepsQuery` - Daily step count data
- `EnergyBurnedQuery` - Active energy burned (calories)
- `WorkoutQuery` - Specific workout type durations
- `ElevatedHeartRateQuery` - Exercise/elevated heart rate time
- `SleepQuery` - Sleep analysis data
- `StandingQuery` - Stand time data

## Measurement Types

The app supports 10 different measurement types organized into three categories:

### Count-Based Measurements
```swift
case steps = "STEPS"           // Daily step count
case energyBurned = "ENERGY_BURNED"  // Active calories burned
```

### Workout-Based Measurements (Time)
```swift
case walking = "WALKING"
case running = "RUNNING"
case cycling = "CYCLING"
case swimming = "SWIMMING"
case yoga = "YOGA"
case strengthTraining = "STRENGTH_TRAINING"
```

### Body State Measurements (Time)
```swift
case elevatedHeartRate = "ELEVATED_HEART_RATE"
case asleep = "ASLEEP"
case standing = "STANDING"
```

## Data Flow Architecture

### 1. Authorization Flow
```
App Launch → Request HealthKit Permissions → Setup Background Observers
```

**HealthKit Permissions Requested:**
- Workout data (HKWorkoutType)
- Active energy burned
- Step count
- Apple exercise time
- High heart rate events
- Sleep analysis
- Apple stand time

### 2. Matchup Health Data Collection
```
Active Matchup → Query Health Data → Process Measurements → Upload to Backend → Post Notifications
```

**Detailed Flow:**
1. **Trigger**: User views matchup or background observer detects new health data
2. **Query**: Execute appropriate query handlers for matchup measurement types
3. **Process**: Convert HealthKit data to app measurement format
4. **Upload**: Send measurements to backend via `UserMeasurementService`
5. **Notify**: Post `.healthDataUpdated` or `.workoutsRecorded` notifications
6. **UI Update**: UI components receive notifications and refresh

### 3. Background Processing
```
HealthKit Observer → Background Task → Query Active Matchups → Update Health Data → Notify UI
```

**Background Observer Types:**
- `HKObserverQuery` for each health data type
- Background delivery enabled for immediate updates
- Throttled to prevent excessive processing (60-second minimum interval)

## Data Models

### MatchupUserMeasurement
Core data structure representing a user's health measurement for a specific day of a matchup:

```swift
struct MatchupUserMeasurement: Codable, Equatable {
    let matchupId: String      // Which matchup this belongs to
    let dayNumber: Int         // Day within the matchup (0-based)
    let measurementType: MeasurementType  // Type of measurement
    let userId: String         // User who owns this measurement
    let value: Int            // Raw measurement value
    let points: Int           // Points calculated by backend
}
```

### Workout Data
```swift
struct Workout: Codable, Identifiable, Equatable {
    let id: String                    // HealthKit UUID
    let user: UserSummary            // User who performed workout
    let workoutStartTime: Date       // When workout started
    let workoutEndTime: Date         // When workout ended
    let type: WorkoutType           // Type of workout
    let displayName: String         // Human-readable name
    let measurements: [WorkoutMeasurement]  // Associated measurements
}
```

## Notification System

### Health Data Notifications
The app uses a notification-based architecture for real-time health data updates:

**`.healthDataUpdated`**
- Posted when health measurements are successfully uploaded
- Payload: Updated `MatchupDetails` object
- Triggers UI refresh in MatchupCards and MatchupDetailViews

**`.workoutsRecorded`**
- Posted when workout data is successfully uploaded
- Payload: `MatchupDetails` object
- Triggers full matchup data reload to get updated points

### Notification Flow
```swift
// Posting notification
NotificationCenter.default.post(
    name: .healthDataUpdated,
    object: updatedMatchupDetails
)

// Observing notification
NotificationCenter.default.publisher(for: .healthDataUpdated)
    .compactMap { $0.object as? MatchupDetails }
    .filter { $0.id == self.matchupId }
    .sink { [weak self] updatedMatchup in
        self?.matchup = updatedMatchup
    }
```

## Privacy & Security

### Data Minimization
- Only requests necessary HealthKit permissions
- Queries are scoped to matchup timeframes only
- No persistent local storage of health data

### User Control
- Users must explicitly grant HealthKit permissions
- Health data queries only run for active matchups
- Users can revoke permissions through iOS Settings

### Background Processing
- Uses Apple's background task system
- Respects iOS battery and performance guidelines
- Includes throttling to prevent excessive background processing

## Performance Optimizations

### Query Efficiency
- **Day-based querying**: Queries are executed per day to enable incremental updates
- **Dispatch groups**: Multiple measurement types queried concurrently
- **Background queues**: Health data processing runs off main thread

### Caching Strategy
- **No local caching**: Relies on HealthKit's internal caching
- **Backend caching**: Server handles measurement deduplication
- **UI-level caching**: ViewModels cache loaded data with timestamps

### Background Efficiency
- **Observer throttling**: 60-second minimum between background updates
- **Active matchup filtering**: Only processes data for active competitions
- **Batch processing**: Multiple measurements uploaded in single API call

## Error Handling

### HealthKit Errors
- **Permission denied**: Graceful fallback, inform user
- **Data unavailable**: Log warning, continue with available data
- **Query failures**: Retry with exponential backoff

### Network Errors
- **Upload failures**: Log error, rely on future background sync
- **Authentication errors**: Handled by `NetworkClient` token refresh
- **Server errors**: User feedback via global `ErrorManager`

### Background Processing Errors
- **Matchup fetch failures**: Log and continue
- **Individual measurement failures**: Process other measurements
- **Critical failures**: Use background task completion

## Integration Points

### Services
- **`UserMeasurementService`**: Uploads health measurements
- **`WorkoutService`**: Records workout data
- **`MatchupService`**: Fetches active matchups for background processing

### UI Components
- **`MatchupCardViewModel`**: Observes health data notifications
- **`MatchupDetailViewModel`**: Displays detailed health measurements
- **Health permission prompts**: Integrated into onboarding flow

### App Lifecycle
- **Foreground**: Immediate health data updates on matchup views
- **Background**: Automatic updates via HealthKit observers
- **App launch**: Re-establishes HealthKit authorization and observers

## Debugging & Monitoring

### Logging
All health data operations use structured logging via `AppLogger`:

```swift
AppLogger.info("Processing health data update", category: .health)
AppLogger.error("Failed to save measurements: \(error)", category: .data)
```

**Log Categories:**
- `.health` - HealthKit operations
- `.data` - Data processing and uploads
- `.network` - API communications

### Performance Monitoring
- Query execution times logged
- Background processing frequency tracked
- Memory usage monitored for observer leaks

## Development Guidelines

### Adding New Measurement Types

1. **Add enum case** to `MeasurementType`
2. **Create query class** implementing `HealthDataQuery`
3. **Register handler** in `HealthKitDataManager.setupQueryHandlers()`
4. **Add HealthKit permission** if needed
5. **Update UI formatting** logic
6. **Test with real device** and HealthKit data

### Testing Considerations

- **Unit tests**: Mock HealthKit data and test query logic
- **Integration tests**: Test notification flow end-to-end
- **Device testing**: Essential for HealthKit integration
- **Background testing**: Verify observers work when app backgrounded
- **Permission testing**: Test various authorization states

### Best Practices

1. **Always check authorization** before querying HealthKit
2. **Use weak references** in notification observers to prevent retain cycles
3. **Handle nil values** gracefully (HealthKit data may be unavailable)
4. **Throttle background processing** to respect battery life
5. **Log extensively** for debugging health data issues
6. **Test on physical devices** - HealthKit doesn't work in simulator

## Future Enhancements

### Potential Improvements
- **Debounced notifications** for rapid health data changes
- **Local data persistence** for offline capability
- **Advanced workout detection** using motion sensors
- **Health trends analysis** for user insights
- **Custom measurement types** for specialized competitions

### Scalability Considerations
- **Batch query optimization** for large date ranges
- **Background processing limits** as user base grows
- **Server-side health data validation** for accuracy
- **Regional health data compliance** (GDPR, HIPAA)

This architecture provides a robust, privacy-respecting foundation for integrating health data into competitive fitness experiences while maintaining excellent performance and user experience.