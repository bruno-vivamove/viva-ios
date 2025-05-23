import Foundation

enum WorkoutType: String, Codable {
    case basketball = "BASKETBALL"
    case walking = "WALKING"
    case running = "RUNNING"
    case cycling = "CYCLING"
    case swimming = "SWIMMING"
    case strengthTraining = "STRENGTH_TRAINING"
    case functionalStrengthTraining = "FUNCTIONAL_STRENGTH_TRAINING"
    case yoga = "YOGA"
    case dancing = "DANCING"
    case hiking = "HIKING"
    case football = "FOOTBALL"
    case soccer = "SOCCER"
    case martialArts = "MARTIAL_ARTS"
    case pilates = "PILATES"
    case rowing = "ROWING"
    case tennis = "TENNIS"
    case tableTennis = "TABLE_TENNIS"
    case bowling = "BOWLING"
    case fishing = "FISHING"
    case volleyball = "VOLLEYBALL"
    case flexibility = "FLEXIBILITY"
    case socialDance = "SOCIAL_DANCE"
    case cardioDance = "CARDIO_DANCE"
    case coreTraining = "CORE_TRAINING"
    case hiit = "HIGH_INTENSITY_INTERVAL_TRAINING"
    case crossTraining = "CROSS_TRAINING"
    case barre = "BARRE"
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
