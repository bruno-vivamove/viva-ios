import SwiftUI

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
