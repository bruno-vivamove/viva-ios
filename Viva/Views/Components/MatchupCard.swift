import SwiftUI

struct MatchupCard: View {
    let matchup: Matchup

    var body: some View {
        VivaCard {
            HStack {
                // Left User
                HStack(spacing: VivaDesign.Spacing.small) {
                    let user = matchup.leftUsers.first
                    
                    VivaProfileImage(
                        imageUrl: user?.imageUrl,
                        size: .small
                    )

                    LabeledValueStack(
                        label: user?.displayName ?? "Open Position",
                        value: "\(1000)",
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
                    let user = matchup.rightUsers.first

                    LabeledValueStack(
                        label: user?.displayName ?? "Open Position",
                        value: "\(1000)",
                        alignment: .trailing
                    )

                    VivaProfileImage(
                        imageUrl: user?.imageUrl,
                        size: .small
                    )
                }
            }
        }
    }
}
