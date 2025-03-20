import BackgroundTasks
import Foundation

class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
    private let backgroundTaskIdentifier = "io.vivamove.healthupdate"
    
    /// The minimum interval between background refreshes (in seconds)
    private let minimumRefreshInterval: TimeInterval = 15 * 60 // 15 minutes
    
    /// Registers the background task with the system
    public func registerBackgroundTasks() {
        // Register for the app refresh task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: backgroundTaskIdentifier,
            using: nil
        ) { task in
            self.handleAppRefreshTask(task: task as! BGAppRefreshTask)
        }
        print("✅ Registered background app refresh task: \(backgroundTaskIdentifier)")
    }

    /// Schedules the background app refresh task
    func scheduleHealthUpdateTask() {
        // Cancel any previously scheduled tasks with the same identifier
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: backgroundTaskIdentifier)
        
        // Create a new app refresh request
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        
        // Set the earliest begin date to respect the minimum refresh interval
        request.earliestBeginDate = Date(timeIntervalSinceNow: minimumRefreshInterval)

        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Successfully scheduled background app refresh task for \(request.earliestBeginDate?.description ?? "unknown time")")
        } catch {
            print("❌ Could not schedule background app refresh task: \(error.localizedDescription)")
            print("Error details: \(error)")
        }
    }

    /// Handles execution of the background app refresh task
    private func handleAppRefreshTask(task: BGAppRefreshTask) {
        print("🔄 Running background health update task...")
        
        // Create a task to reschedule this background task when it completes
        // This ensures we always schedule the next refresh when this one finishes
        let rescheduleTask = {
            self.scheduleHealthUpdateTask()
        }
        
        // Set up expiration handler to ensure we reschedule even if the task expires
        task.expirationHandler = {
            print("⚠️ Background task expired")
            rescheduleTask()
            task.setTaskCompleted(success: false)
        }
        
        // Perform the actual health data update
        Task {
            do {
                let vivaAppObjects = VivaAppObjects()
                let result = try await vivaAppObjects.healthService.ping()
                print("✅ HealthService Ping Result: \(result)")
                
                // Optional: Update app UI if needed
                NotificationCenter.default.post(name: .healthDataUpdated, object: nil)
                
                // Mark task as successfully completed
                task.setTaskCompleted(success: true)
            } catch {
                print("❌ Failed to update health data: \(error)")
                task.setTaskCompleted(success: false)
            }
            
            // Always reschedule the next task after completion
            rescheduleTask()
        }
    }
}
