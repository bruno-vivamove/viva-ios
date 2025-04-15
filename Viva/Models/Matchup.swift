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
    let pagination: Pagination
}

struct Pagination: Codable {
    let page: Int
    let pageSize: Int
    let total: Int
    let totalPages: Int
}

struct MatchupTeam: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let teamHash: String?
    let side: Side
    let points: Int
    let winCount: Int
    let users: [User]
    
    enum Side: String, Codable {
        case left = "LEFT"
        case right = "RIGHT"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MatchupTeam, rhs: MatchupTeam) -> Bool {
        lhs.id == rhs.id
    }
}

struct Matchup: Codable, Identifiable, Equatable, Hashable {
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
    let teams: [MatchupTeam]
    var invites: [MatchupInvite]

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Matchup, rhs: Matchup) -> Bool {
        lhs.id == rhs.id
    }
    
    var leftTeam: MatchupTeam? {
        teams.first { $0.side == .left }
    }
    
    var rightTeam: MatchupTeam? {
        teams.first { $0.side == .right }
    }
    
    var leftUsers: [User] {
        leftTeam?.users ?? []
    }
    
    var rightUsers: [User] {
        rightTeam?.users ?? []
    }
    
    var leftSidePoints: Int {
        leftTeam?.points ?? 0
    }
    
    var rightSidePoints: Int {
        rightTeam?.points ?? 0
    }
}

struct MatchupDetails: Codable, Equatable {
    let id: String
    let matchupHash: String?
    let displayName: String
    let ownerId: String
    let createTime: Date
    var status: MatchupStatus
    let startTime: Date?
    let endTime: Date?
    let usersPerSide: Int
    let lengthInDays: Int
    let teams: [MatchupTeam]
    let measurements: [MatchupMeasurement]
    var userMeasurements: [MatchupUserMeasurement]
    var invites: [MatchupInvite]
    var finalized: Bool
    
    var leftTeam: MatchupTeam {
        teams.first { $0.side == .left }!
    }
    
    var rightTeam: MatchupTeam {
        teams.first { $0.side == .right }!
    }

    var currentDayNumber: Int? {
        guard let startTime = self.startTime else {
            return nil
        }
        
        let now = Date()
        let dayLength = 24 * 60 * 60
        let elapsedSeconds = now.timeIntervalSince(startTime)
        let currentDayNumber = Int(floor(elapsedSeconds / Double(dayLength)))

        if currentDayNumber < 0 {
            return nil
        }
        
        if(currentDayNumber >= self.lengthInDays) {
            return lengthInDays - 1
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
            teams: teams,
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
    let side: MatchupTeam.Side
    let userOrder: Int
    let createTime: Date?
    let userInfo: User?
}

struct MatchupMeasurement: Codable, Equatable {
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

struct MatchupUserMeasurement: Codable, Equatable {
    let matchupId: String
    let dayNumber: Int
    let measurementType: MeasurementType
    let userId: String
    let completeDay: Bool
    let value: Int
    let points: Int
}

struct MatchupUserMeasurements: Codable {
    let matchupUserMeasurements: [MatchupUserMeasurement]
}

struct MatchupMeasurementPair: Codable, Equatable {
    let measurementType: MeasurementType
    var leftValue: Int
    var leftPoints: Int
    var rightValue: Int
    var rightPoints: Int
}

struct MatchupStats: Codable, Equatable {
    let matchupHash: String?
    let displayName: String
    let numberOfMatchups: Int
    let userTeamWins: Int
    let opponentTeamWins: Int
    let userTeamUsers: [User]
    let opponentTeamUsers: [User]
}

struct UserStats: Codable, Equatable {
    let userId: String
    let displayName: String
    let totalMatchups: Int
    let wins: Int
    let losses: Int
    let ties: Int
}

struct MatchupStatsResponse: Codable {
    let userStats: UserStats
    let matchupStats: [MatchupStats]
}

enum MatchupFilter: String, Codable {
    case ALL = "ALL"
    case ACTIVE = "ACTIVE"
    case COMPLETED = "COMPLETED"
    case UNFINALIZED = "UNFINALIZED"
}

struct RematchRequest: Codable {
    let displayName: String
    private let measurementTypes: [String]
    
    init(displayName: String, measurementTypes: [MeasurementType]) {
        self.displayName = displayName
        self.measurementTypes = measurementTypes.map { $0.rawValue }
    }
}
