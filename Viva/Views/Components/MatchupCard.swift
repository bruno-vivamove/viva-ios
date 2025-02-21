import SwiftUI

struct MatchupCard: View {
    let matchup: Matchup
    let onCancel: (() -> Void)?

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
                        value: "\(0)",
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
                        value: "\(0)",
                        alignment: .trailing
                    )

                    VivaProfileImage(
                        imageUrl: user?.imageUrl,
                        size: .small
                    )
                }
            }
        }
        .background(Color.black)  // Add black background to card
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if matchup.status == .pending {
                Button(role: .destructive) {
                    onCancel?()
                } label: {
                    Text("Cancel")
                }
                .tint(.red)  // Use explicit red tint for destructive action
            }
        }
    }
}
