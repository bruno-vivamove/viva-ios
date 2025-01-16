import SwiftUI

struct MatchupCard: View {
    let matchup: Matchup

    var body: some View {
        VivaCard {
            HStack {
                // Left User
                HStack(spacing: VivaDesign.Spacing.small) {
                    VivaProfileImage(
                        imageId: matchup.leftUsers[0].user.imageId,
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
                        imageId: matchup.rightUsers[0].user.imageId,
                        size: .small
                    )
                }
            }
        }
    }
}
