import SwiftUI

struct FriendCard: View {
    let user: User

    var body: some View {
        VivaCard {
            HStack {
                // User Info
                HStack(spacing: VivaDesign.Spacing.small) {
                    VivaProfileImage(
                        imageUrl: user.imageUrl,
                        size: .small
                    )

                    Text(user.displayName)
                        .foregroundColor(VivaDesign.Colors.primaryText)
                        .font(VivaDesign.Typography.body)
                }

                Spacer()

                // Challenge Button
                VivaPrimaryButton(
                    title: "Challenge",
                    width: 100
                ) {
                    // Add challenge action
                }
            }
        }
    }
}
