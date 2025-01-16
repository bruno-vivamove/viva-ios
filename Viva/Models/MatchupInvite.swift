struct MatchupInvite {
    let id: String
    let user: User
    let type: InvitationType
}

enum InvitationType {
    case sent
    case received
}
