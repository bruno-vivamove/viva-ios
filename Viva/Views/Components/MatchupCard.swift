import SwiftUI

struct MatchupCard: View {
    let matchup: Matchup

    var body: some View {
        VivaCard {
            HStack {
                // Left User
                HStack(spacing: VivaDesign.Spacing.small) {
                    VivaProfileImage(
                        imageUrl: matchup.leftUsers[0].user.imageUrl,
                        size: .small
                    )

                    LabeledValueStack(
                        label: matchup.leftUsers[0].user.displayName,
                        value: "\(matchup.leftUsers[0].score)",
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
                        label: matchup.rightUsers[0].user.displayName,
                        value: "\(matchup.rightUsers[0].score)",
                        alignment: .trailing
                    )

                    VivaProfileImage(
                        imageUrl: matchup.rightUsers[0].user.imageUrl,
                        size: .small
                    )
                }
            }
        }
    }
}
