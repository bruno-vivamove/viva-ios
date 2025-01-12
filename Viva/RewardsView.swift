import SwiftUI

struct RewardsView: View {
    private let points = 3017 // This could be passed in or managed by a view model
    private let logoWidth: CGFloat = 120
    private let horizontalPadding: CGFloat = 20

    var body: some View {
        VStack(spacing: 0) {
            // Points Display
            VStack(spacing: 4) {
                Text("\(points)")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Reward Points")
                    .font(.system(size: 24))
                    .foregroundColor(.vivaGreen)
            }
            .padding(.vertical, 24)  // Less vertical padding
            .padding(.horizontal, 50)  // More horizontal padding
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
            .padding(.top, 40)
            
            Spacer()
            
            // Logo and Title
            VStack(spacing: 4) {
                HStack {
                    Spacer()
                    Image("viva_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: logoWidth)
                }

                Text("Marketplace")
                    .foregroundColor(.vivaGreen)
                    .font(.system(size: 22))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            // Coming Soon Text
            VStack {
                Text("COMING SOON")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
                    .font(.system(size: 1000).leading(.tight))  // Large initial size that will be scaled down
                    .minimumScaleFactor(0.01)
            }  // Allow significant scaling
            
            // Description Text
            HStack {
                Spacer()
                Text("Redeem Viva Reward Points for discounts and credit towards a curated selection of healthy brands.")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.5)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, horizontalPadding)
        .background(Color.black)
    }
}

#Preview {
    RewardsView()
}
