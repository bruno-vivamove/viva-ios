import Foundation

struct MatchupRequest: Codable {
    let displayName: String
    let usersPerSide: Int
    private let measurementTypes: [String]
    
    init(displayName: String, usersPerSide: Int, measurementTypes: [MeasurementType]) {
        self.displayName = displayName
        self.usersPerSide = usersPerSide
        self.measurementTypes = measurementTypes.map { $0.rawValue }
    }
}

struct MatchupsResponse: Codable {
    let matchups: [Matchup]
}

struct Matchup: Codable, Identifiable {
    let id: String
    let matchupHash: String?
    let displayName: String
    let ownerId: String
    let createTime: Date
    let status: MatchupStatus
    let startTime: Date?
    let endTime: Date?
    let usersPerSide: Int
    let lengthInDays: Int
    let leftSidePoints: Int
    let rightSidePoints: Int
    let leftUsers: [User]
    let rightUsers: [User]
    var invites: [MatchupInvite]
}

struct MatchupDetails: Codable {
    let id: String
    let matchupHash: String?
    let displayName: String
    let ownerId: String
    let createTime: Date
    let status: MatchupStatus
    let startTime: Date?
    let endTime: Date?
    let usersPerSide: Int
    let lengthInDays: Int
    let leftSidePoints: Int
    let rightSidePoints: Int
    let leftUsers: [User]
    let rightUsers: [User]

    let measurements: [MatchupMeasurement]
    var userMeasurements: [MatchupUserMeasurement]
    var invites: [MatchupInvite]

    var currentDayNumber: Int? {
        guard let startTime = self.startTime else {
            return nil
        }
        
        let now = Date()
        let dayLength = 24 * 60 * 60
        let elapsedSeconds = now.timeIntervalSince(startTime)
        let currentDayNumber = Int(floor(elapsedSeconds / Double(dayLength)))

        if currentDayNumber < 0
            || (self.endTime != nil && now > self.endTime!)
        {
            return nil
        }
        
        return currentDayNumber
    }

    var asMatchup: Matchup {
        Matchup(
            id: id,
            matchupHash: matchupHash,
            displayName: displayName,
            ownerId: ownerId,
            createTime: createTime,
            status: status,
            startTime: startTime,
            endTime: endTime,
            usersPerSide: usersPerSide,
            lengthInDays: lengthInDays,
            leftSidePoints: leftSidePoints,
            rightSidePoints: rightSidePoints,
            leftUsers: leftUsers,
            rightUsers: rightUsers,
            invites: invites
        )
    }
}

enum MatchupStatus: String, Codable {
    case pending = "PENDING"
    case active = "ACTIVE"
    case completed = "COMPLETED"
    case cancelled = "CANCELLED"
}

struct MatchupUser: Codable {
    let userId: String
    let matchupId: String
    let side: Side
    let userOrder: Int
    let createTime: Date?
    let userInfo: User?
    
    enum Side: String, Codable {
        case left = "L"
        case right = "R"
    }
}

struct MatchupMeasurement: Codable {
    let matchupId: String
    let measurementType: MeasurementType
    let displayOrder: Int
}

// Enums
enum MeasurementType: String, Codable {
    // Counts
    case steps = "STEPS"
    case energyBurned = "ENERGY_BURNED"
    
    // Workouts (time)
    case walking = "WALKING"
    case running = "RUNNING"
    case cycling = "CYCLING"
    case swimming = "SWIMMING"
    case yoga = "YOGA"
    case strengthTraining = "STRENGTH_TRAINING"
    
    // Body States (time)
    case elevatedHeartRate = "ELEVATED_HEART_RATE"
    case asleep = "ASLEEP"
    case standing = "STANDING"
}

struct MatchupUserMeasurement: Codable {
    let matchupId: String
    let dayNumber: Int
    let measurementType: MeasurementType
    let userId: String
    let completeDay: Bool
    let value: Int
    let points: Int
}

struct MatchupMeasurementPair: Codable {
    let measurementType: MeasurementType
    var leftValue: Int
    var leftPoints: Int
    var rightValue: Int
    var rightPoints: Int
}
