import SwiftUI
import Foundation


struct HomeView: View {
    private let liveMatchups = [
        Matchup(
            id: "1",
            leftUsers: [MatchupUser(
                user: User(
                    id: "1", displayName: "Saya Jones",
                    imageId: "profile_stock"),
                score: 1275
            )],
            rightUsers: [MatchupUser(
                user: User(
                    id: "2", displayName: "Chris Dolan",
                    imageId: "profile_chris"),
                score: 1287
            )],
            endDate: ISO8601DateFormatter().date(from: "2025-01-16T11:00:00Z")!
        ),
        Matchup(
            id: "2",
            leftUsers: [MatchupUser(
                user: User(
                    id: "2", displayName: "Saya Jones",
                    imageId: "profile_stock"),
                score: 1225
            )],
            rightUsers: [MatchupUser(
                user: User(
                    id: "3", displayName: "Bruno Souto",
                    imageId: "profile_bruno"),
                score: 1168
            )],
            endDate: ISO8601DateFormatter().date(from: "2025-01-17T11:00:00Z")!
        ),
        Matchup(
            id: "3",
            leftUsers: [MatchupUser(
                user: User(
                    id: "3", displayName: "Saya Jones",
                    imageId: "profile_stock"),
                score: 1175
            )],
            rightUsers: [MatchupUser(
                user: User(
                    id: "4", displayName: "Judah Levine",
                    imageId: "profile_judah"),
                score: 1113
            )],
            endDate: ISO8601DateFormatter().date(from: "2025-01-18T11:00:00Z")!
        ),
    ]


    private let pendingInvitations = [
        MatchupInvite(
            id: "1",
            user: User(
                id: "5", displayName: "Chris Dolan",
                imageId: "profile_chris"),
            type: .sent
        ),
        MatchupInvite(
            id: "2",
            user: User(
                id: "6", displayName: "Adson Afonso",
                imageId: "profile_bruno"
            ),
            type: .sent
        ),
        MatchupInvite(
            id: "3",
            user: User(
                id: "7", displayName: "Judah Levine",
                imageId: "profile_judah"
            ),
            type: .sent
        ),
        MatchupInvite(
            id: "4",
            user: User(
                id: "8", displayName: "Chris Dolan",
                imageId: "profile_chris"
            ),
            type: .received
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
                            ForEach(liveMatchups, id: \.id) {
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

#Preview {
    HomeView()
}
