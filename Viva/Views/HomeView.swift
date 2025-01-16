import SwiftUI

struct HomeView: View {
    private let liveMatchups = [
        Matchup(
            id: "1",
            leftUser: User(
                id: "1", displayName: "Saya Jones", rewardPoints: 1275,
                imageId: "profile_stock"),
            rightUser: User(
                id: "2", displayName: "Chris Dolan", rewardPoints: 1287,
                imageId: "profile_chris"),
            timeLeft: "1d 11h left"
        ),
        Matchup(
            id: "2",
            leftUser: User(
                id: "2", displayName: "Saya Jones", rewardPoints: 1225,
                imageId: "profile_stock"),
            rightUser: User(
                id: "3", displayName: "Bruno Souto", rewardPoints: 1168,
                imageId: "profile_bruno"),
            timeLeft: "1d 11h left"
        ),
        Matchup(
            id: "3",
            leftUser: User(
                id: "3", displayName: "Saya Jones", rewardPoints: 1175,
                imageId: "profile_stock"),
            rightUser: User(
                id: "4", displayName: "Judah Levine", rewardPoints: 1113,
                imageId: "profile_judah"),
            timeLeft: "1d 11h left"
        ),
    ]

    private let pendingInvitations = [
        MatchupInvite(
            user: User(
                id: "5", displayName: "Chris Dolan", rewardPoints: 0,
                imageId: "profile_chris"),
            type: .sent
        ),
        MatchupInvite(
            user: User(
                id: "6", displayName: "Adson Afonso", rewardPoints: 0,
                imageId: "profile_bruno"
            ),
            type: .sent
        ),
        MatchupInvite(
            user: User(
                id: "7", displayName: "Judah Levine", rewardPoints: 0,
                imageId: "profile_judah"
            ),
            type: .sent
        ),
        MatchupInvite(
            user: User(
                id: "8", displayName: "Chris Dolan", rewardPoints: 0,
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
