struct MatchupInvite {
    let user: User
    let type: InvitationType
}

enum InvitationType {
    case sent
    case received
}
