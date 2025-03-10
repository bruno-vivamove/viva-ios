import Foundation

extension Notification.Name {
    static let matchupCreated = Notification.Name("matchupCreated")
    static let matchupUpdated = Notification.Name("matchupUpdated")
    static let matchupStarted = Notification.Name("matchupCreated")
    static let matchupCanceled = Notification.Name("matchupCanceled")

    static let matchupUserAdded = Notification.Name("matchupUserAdded")
    static let matchupUserRemoved = Notification.Name("matchupUserRemoved")

    static let matchupInviteSent = Notification.Name("matchupInviteSent")
    static let matchupInviteDeleted = Notification.Name("matchupInviteDeleted")
    static let matchupInviteAccepted = Notification.Name("matchupInviteAccepted")

    static let friendRequestSent = Notification.Name("friendRequestSent")
    
    
    static let homeScreenMatchupCreationCompleted = Notification.Name("homeScreenMatchupCreationCompleted")
    static let friendScreenMatchupCreationCompleted = Notification.Name("friendScreenMatchupCreationCompleted")
}
