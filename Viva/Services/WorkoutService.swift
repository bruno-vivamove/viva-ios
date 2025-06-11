import Foundation

final class WorkoutService: ObservableObject {
    private let networkClient: NetworkClient<VivaErrorResponse>
    
    init(networkClient: NetworkClient<VivaErrorResponse>) {
        self.networkClient = networkClient
    }
    
    // MARK: - Workouts
    
    func getWorkouts(page: Int = 1, pageSize: Int = 20) async throws -> WorkoutListResponse {
        return try await networkClient.get(
            path: "/workouts",
            queryParams: [
                "page": String(page),
                "pageSize": String(pageSize)
            ]
        )
    }
    
    func getWorkout(workoutId: String) async throws -> WorkoutResponse {
        return try await networkClient.get(
            path: "/workouts/\(workoutId)"
        )
    }
    
    func recordWorkouts(workouts: [Workout]) async throws {
        let request = RecordWorkoutsRequest(workouts: workouts)
        
        try await networkClient.post(
            path: "/workouts",
            body: request
        )
        
        NotificationCenter.default.post(
            name: .workoutsRecorded,
            object: nil
        )
    }
}
