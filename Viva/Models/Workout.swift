import Foundation

enum WorkoutType: String, Codable {
    case basketball = "BASKETBALL"
    case other = "OTHER"
}

struct WorkoutMeasurement: Codable, Equatable {
    let workoutId: String
    let measurementType: MeasurementType
    let value: Int
}

struct Workout: Codable, Identifiable, Equatable {
    let id: String
    let user: UserSummary
    let workoutStartTime: Date
    let workoutEndTime: Date
    let type: WorkoutType
    let displayName: String
    let measurements: [WorkoutMeasurement]
}

struct WorkoutResponse: Codable {
    let workout: Workout
}

struct WorkoutListResponse: Codable {
    let workouts: [Workout]
    let pagination: PaginationMetadata
}

struct RecordWorkoutsRequest: Codable {
    let workouts: [Workout]
} 
