import BackgroundTasks
import Foundation

class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()

    /// Registers the background task with the system
    public func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "io.vivamove.healthupdate",
            using: nil
        ) { task in
            self.handleHealthUpdateTask(task: task as! BGProcessingTask)
        }
        print("✅ Registered background task: io.vivamove.healthupdate")
    }

    /// Schedules the background task
    func scheduleHealthUpdateTask() {
        let request = BGProcessingTaskRequest(identifier: "io.vivamove.healthupdate")
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 10) // Run in 10 seconds

        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Successfully scheduled background task")
        } catch {
            // Basic error information
            print("❌ Could not schedule background task: \(error.localizedDescription)")
            print("Error: \(error)")
        }
    }

    /// Handles execution of the background task
    private func handleHealthUpdateTask(task: BGProcessingTask) {
        print("🔄 Running background health update task...")

        Task {
            do {
                let vivaAppObjects = VivaAppObjects()
                let result = try await vivaAppObjects.healthService.ping()
                print("✅ HealthService Ping Result: \(result)")
                task.setTaskCompleted(success: true)
            } catch {
                print("❌ Failed to update health data: \(error)")
                task.setTaskCompleted(success: false)
            }
        }

        task.expirationHandler = {
            print("⚠️ Background task expired")
            task.setTaskCompleted(success: false)
        }

        // Reschedule the task
        scheduleHealthUpdateTask()
    }
}
