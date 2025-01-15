//
//  HomeView.swift
//  Viva
//
//  Created by Bruno Souto on 1/9/25.
//

import SwiftUI

struct Matchup {
    let id: String
    let leftUser: User
    let rightUser: User
    let timeLeft: String
}

struct PendingInvitation {
    let user: User
    let type: InvitationType
}

enum InvitationType {
    case accept
    case remind
}

struct HomeView: View {
    private let liveMatchups = [
        Matchup(
            id: "1",
            leftUser: User(
                id: "1", name: "Saya Jones", score: 1275,
                imageURL: "profile_stock"),
            rightUser: User(
                id: "2", name: "Chris Dolan", score: 1287,
                imageURL: "profile_chris"),
            timeLeft: "1d 11h left"
        ),
        Matchup(
            id: "2",
            leftUser: User(
                id: "2", name: "Saya Jones", score: 1225,
                imageURL: "profile_stock"),
            rightUser: User(
                id: "3", name: "Bruno Souto", score: 1168,
                imageURL: "profile_bruno"),
            timeLeft: "1d 11h left"
        ),
        Matchup(
            id: "3",
            leftUser: User(
                id: "3", name: "Saya Jones", score: 1175,
                imageURL: "profile_stock"),
            rightUser: User(
                id: "4", name: "Judah Levine", score: 1113,
                imageURL: "profile_judah"),
            timeLeft: "1d 11h left"
        ),
    ]

    private let pendingInvitations = [
        PendingInvitation(
            user: User(
                id: "5", name: "Chris Dolan", score: 0,
                imageURL: "profile_chris"),
            type: .accept
        ),
        PendingInvitation(
            user: User(
                id: "6", name: "Adson Afonso", score: 0,
                imageURL: "profile_bruno"
            ),
            type: .accept
        ),
        PendingInvitation(
            user: User(
                id: "7", name: "Judah Levine", score: 0,
                imageURL: "profile_judah"
            ),
            type: .accept
        ),
        PendingInvitation(
            user: User(
                id: "8", name: "Chris Dolan", score: 0,
                imageURL: "profile_chris"
            ),
            type: .remind
        ),
    ]

    var body: some View {
        VStack(spacing: VivaDesign.Spacing.medium) {
            HomeHeader()
                .padding(.top, VivaDesign.Spacing.small)
                .padding(.horizontal, VivaDesign.Spacing.medium)

            ScrollView {
                VStack(spacing: VivaDesign.Spacing.medium) {
                    // Live Matchups Section
                    VStack(
                        alignment: .leading, spacing: VivaDesign.Spacing.small
                    ) {
                        Text("Live Matchups")
                            .font(VivaDesign.Typography.header)
                            .foregroundColor(VivaDesign.Colors.primaryText)
                            .padding(.horizontal)

                        VStack(spacing: VivaDesign.Spacing.small) {
                            ForEach(liveMatchups, id: \.rightUser.id) {
                                matchup in
                                MatchupCard(matchup: matchup)
                            }
                        }
                    }
                    .padding(.horizontal, VivaDesign.Spacing.medium)

                    // Pending Invitations Section
                    VStack(
                        alignment: .leading, spacing: VivaDesign.Spacing.small
                    ) {
                        Text("Pending Invitations")
                            .font(VivaDesign.Typography.header)
                            .foregroundColor(VivaDesign.Colors.primaryText)
                            .padding(.horizontal)

                        VStack(spacing: VivaDesign.Spacing.small) {
                            ForEach(pendingInvitations, id: \.user.id) {
                                invitation in
                                InvitationCard(invitation: invitation)
                            }
                        }
                    }
                    .padding(.horizontal, VivaDesign.Spacing.medium)
                }

            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VivaDesign.Colors.background)
    }
}

#Preview {
    HomeView()
}

struct HomeHeader: View {
    var body: some View {
        HStack(spacing: VivaDesign.Spacing.medium) {
            LabeledValueStack(
                label: "Streak", value: "17 Wks", alignment: .leading)

            LabeledValueStack(
                label: "Points", value: "3,017", alignment: .leading)

            Spacer()

            VivaPrimaryButton(
                title: "Create New Matchup"
            ) {
                // Add action here
            }
        }
    }
}

struct MatchupCard: View {
    let matchup: Matchup

    var body: some View {
        VivaCard {
            HStack {
                // Left User
                HStack(spacing: VivaDesign.Spacing.small) {
                    VivaProfileImage(
                        imageURL: matchup.leftUser.imageURL,
                        size: .small
                    )

                    LabeledValueStack(
                        label: matchup.leftUser.name,
                        value: "\(matchup.leftUser.score)",
                        alignment: .leading
                    )
                }

                Spacer()

                // Divider
                Text("|")
                    .foregroundColor(VivaDesign.Colors.secondaryText)
                    .font(VivaDesign.Typography.title3)

                Spacer()

                // Right User
                HStack(spacing: VivaDesign.Spacing.small) {
                    LabeledValueStack(
                        label: matchup.rightUser.name,
                        value: "\(matchup.rightUser.score)",
                        alignment: .trailing
                    )

                    VivaProfileImage(
                        imageURL: matchup.rightUser.imageURL,
                        size: .small
                    )
                }
            }
        }
    }
}

struct InvitationCard: View {
    let invitation: PendingInvitation
    private let buttonWidth: CGFloat = 120

    var body: some View {
        VivaCard {
            HStack {
                // Action Buttons Container
                VStack(spacing: VivaDesign.Spacing.minimal) {
                    VivaPrimaryButton(
                        title: invitation.type == .accept ? "Accept" : "Remind",
                        width: buttonWidth
                    ) {
                        // Add action here

                    }

                    if invitation.type == .accept {
                        VivaSecondaryButton(title: "Delete", width: buttonWidth)
                        {
                            // Add action here
                        }
                    }
                }

                Spacer()

                // User Info
                HStack(spacing: VivaDesign.Spacing.small) {
                    Text(invitation.user.name)
                        .foregroundColor(VivaDesign.Colors.vivaGreen)
                        .font(VivaDesign.Typography.caption)

                    VivaProfileImage(
                        imageURL: invitation.user.imageURL,
                        size: .small
                    )
                }
            }
        }
    }
}
