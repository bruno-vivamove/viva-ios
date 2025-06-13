import Foundation

extension Notification.Name {
    static let matchupCreated = Notification.Name("matchupCreated")
    static let matchupUpdated = Notification.Name("matchupUpdated")
    static let matchupStarted = Notification.Name("matchupStarted")
    static let matchupCanceled = Notification.Name("matchupCanceled")

    static let matchupUserAdded = Notification.Name("matchupUserAdded")
    static let matchupUserRemoved = Notification.Name("matchupUserRemoved")

    static let matchupInviteSent = Notification.Name("matchupInviteSent")
    static let matchupInviteDeleted = Notification.Name("matchupInviteDeleted")
    static let matchupInviteAccepted = Notification.Name("matchupInviteAccepted")

    static let friendRequestSent = Notification.Name("friendRequestSent")
    
    static let userProfileUpdated = Notification.Name("userProfileUpdated")
    
    static let matchupCreationFlowCompleted = Notification.Name("matchupCreationFlowCompleted")        

    // Notification sent when health data is updated in the background
    static let healthDataUpdated = Notification.Name("healthDataUpdated")
    
    // Workout notifications
    static let workoutsRecorded = Notification.Name("workoutsRecorded")
    
    // Push notification indicator
    static let pushNotificationReceived = Notification.Name("pushNotificationReceived")
}
