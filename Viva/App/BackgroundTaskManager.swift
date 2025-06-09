import BackgroundTasks
import Foundation

class BackgroundTaskManager {
    public static let backgroundHealthUpdateTaskIdentifier =
        "io.vivamove.healthupdate"
    
    private let healthKitDataManager: HealthKitDataManager
    
    init(healthKitDataManager: HealthKitDataManager) {
        self.healthKitDataManager = healthKitDataManager
    }

    /// Registers the background task with the system
    public func registerBackgroundTasks() {
        // Register for the HealthKit processing task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: BackgroundTaskManager
                .backgroundHealthUpdateTaskIdentifier,
            using: nil
        ) { task in
            guard let processingTask = task as? BGProcessingTask else {
                AppLogger.error(
                    "❌ Received unexpected task type: \(type(of: task))",
                    category: .general
                )
                task.setTaskCompleted(success: false)
                return
            }
            self.handleHealthKitProcessingTask(task: processingTask)
        }
        AppLogger.info(
            "✅ Registered background HealthKit processing task: \(BackgroundTaskManager.backgroundHealthUpdateTaskIdentifier)",
            category: .general
        )
    }

    /// Handles execution of the HealthKit processing task
    private func handleHealthKitProcessingTask(task: BGProcessingTask) {
        let startTime = Date()
        AppLogger.info(
            "🔄 Running HealthKit data processing task...",
            category: .health
        )

        // Set up expiration handler
        task.expirationHandler = {
            let elapsed = Date().timeIntervalSince(startTime)
            AppLogger.warning(
                "⚠️ HealthKit processing task expired after \(String(format: "%.1f", elapsed))s",
                category: .health
            )
            task.setTaskCompleted(success: false)
        }

        // Process the health data using the injected dependency
        healthKitDataManager.processHealthDataUpdate()

        // Notify the app of updated health data
        NotificationCenter.default.post(name: .healthDataUpdated, object: nil)

        // Calculate and log execution time
        let executionTime = Date().timeIntervalSince(startTime)
        
        // Mark task as completed
        task.setTaskCompleted(success: true)
        AppLogger.info(
            "✅ Completed HealthKit data processing task in \(String(format: "%.1f", executionTime))s",
            category: .health
        )
    }
}
