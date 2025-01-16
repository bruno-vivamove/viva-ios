import SwiftUI

struct RewardsView: View {
    private let points = 3017
    private let logoWidth: CGFloat = 120

    var body: some View {
        VStack(spacing: 0) {
            RewardsPointsCard(points: points)
                .padding(.top, VivaDesign.Spacing.large)

            Spacer()

            VStack(spacing: 0) {
                MarketplaceHeader(logoWidth: logoWidth)
                HStack {
                    Spacer()
                    Text("COMING SOON")
                        .font(VivaDesign.Typography.displayText())
                        .fontWeight(.bold)
                        .foregroundColor(VivaDesign.Colors.primaryText)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(2)
                        .minimumScaleFactor(0.01)
                }
                HStack {
                    Spacer()
                    Text(
                        "Redeem Viva Reward Points for discounts and credit towards a curated selection of healthy brands."
                    )
                    .font(VivaDesign.Typography.body)
                    .foregroundColor(VivaDesign.Colors.primaryText)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.5)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, VivaDesign.Spacing.medium)
        .background(VivaDesign.Colors.background)
    }
}

#Preview {
    RewardsView()
}

struct RewardsPointsCard: View {
    let points: Int

    var body: some View {
        VivaCard {
            VStack(spacing: VivaDesign.Spacing.minimal) {
                Text("\(points)")
                    .font(VivaDesign.Typography.displayText(60))
                    .foregroundColor(VivaDesign.Colors.primaryText)

                Text("Reward Points")
                    .font(VivaDesign.Typography.title3)
                    .foregroundColor(VivaDesign.Colors.vivaGreen)
            }
            .padding(.vertical, VivaDesign.Spacing.medium)
            .padding(.horizontal, VivaDesign.Spacing.large)
        }
    }
}

struct MarketplaceHeader: View {
    let logoWidth: CGFloat

    var body: some View {
        VStack(spacing: VivaDesign.Spacing.minimal) {
            HStack {
                Spacer()
                Image("viva_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: logoWidth)
            }

            Text("Marketplace")
                .foregroundColor(VivaDesign.Colors.vivaGreen)
                .font(VivaDesign.Typography.title3)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}
