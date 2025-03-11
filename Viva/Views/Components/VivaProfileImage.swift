import SkeletonView
import SwiftUI

struct VivaProfileImage: View {
    let userId: String?
    let imageUrl: String?
    let size: VivaDesign.Sizing.ProfileImage
    let isInvited: Bool
    
    // Configure URL cache
    init(
        userId: String?,
        imageUrl: String?,
        size: VivaDesign.Sizing.ProfileImage,
        isInvited: Bool = false
    ) {
        self.userId = userId
        self.imageUrl = imageUrl
        self.size = size
        self.isInvited = isInvited
    }
    
    var body: some View {
        if let urlString = imageUrl, let url = URL(string: urlString) {
            CachedAsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    SkeletonProfileImageView(
                        size: size.rawValue, isInvited: isInvited
                    )
                    .frame(width: size.rawValue, height: size.rawValue)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size.rawValue, height: size.rawValue)
                        .modifier(InvitedModifier(isInvited: isInvited))
                        .clipShape(Circle())
                case .failure:
                    defaultImage
                        .modifier(InvitedModifier(isInvited: isInvited))
                @unknown default:
                    defaultImage
                        .modifier(InvitedModifier(isInvited: isInvited))
                }
            }
            .clipShape(Circle())
        } else {
            defaultImage
                .clipShape(Circle())
                .modifier(InvitedModifier(isInvited: isInvited))
        }
    }

    private var defaultImage: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .foregroundColor(.gray)
            .frame(width: size.rawValue, height: size.rawValue)
    }
}

// Custom CachedAsyncImage wrapper for enhanced caching
struct CachedAsyncImage<Content: View>: View {
    private let url: URL
    private let scale: CGFloat
    private let transaction: Transaction
    private let content: (AsyncImagePhase) -> Content
    
    init(
        url: URL,
        scale: CGFloat = 1.0,
        transaction: Transaction = Transaction(),
        @ViewBuilder content: @escaping (AsyncImagePhase) -> Content
    ) {
        self.url = url
        self.scale = scale
        self.transaction = transaction
        self.content = content
        
        // Create a URL request with cache policy
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        
        // Check if the image is already cached, and if so, prefetch it
        URLSession.shared.dataTask(with: request) { _, _, _ in }.resume()
    }
    
    var body: some View {
        AsyncImage(
            url: url,
            scale: scale,
            transaction: transaction,
            content: content
        )
    }
}

// UIViewRepresentable wrapper for UIView with SkeletonView
struct SkeletonProfileImageView: UIViewRepresentable {
    let size: CGFloat
    let isInvited: Bool

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView(
            frame: CGRect(x: 0, y: 0, width: size, height: size))
        containerView.backgroundColor = .clear

        let imageView = UIImageView(frame: containerView.bounds)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = size / 2
        imageView.isSkeletonable = true

        containerView.addSubview(imageView)

        // Apply skeleton animation with gradient
        let gradient = SkeletonGradient(
            baseColor: UIColor(Color(red: 0.1, green: 0.1, blue: 0.1)), secondaryColor: UIColor.lightGray)
        let animation = SkeletonAnimationBuilder().makeSlidingAnimation(withDirection: .topLeftBottomRight)
        imageView.showAnimatedGradientSkeleton(usingGradient: gradient, animation: animation)

        // Apply invited modifier if needed
        if isInvited {
            imageView.alpha = 0.6

            let shapeLayer = CAShapeLayer()
            shapeLayer.path =
                UIBezierPath(
                    arcCenter: CGPoint(x: size / 2, y: size / 2),
                    radius: size / 2 - 1,
                    startAngle: 0,
                    endAngle: 2 * .pi,
                    clockwise: true
                ).cgPath
            shapeLayer.fillColor = UIColor.clear.cgColor
            shapeLayer.strokeColor =
                UIColor(named: "VivaGreen")?.cgColor ?? UIColor.green.cgColor
            shapeLayer.lineWidth = 2
            shapeLayer.lineDashPattern = [5, 5]

            containerView.layer.addSublayer(shapeLayer)
        }

        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Update view if needed
    }
}

struct InvitedModifier: ViewModifier {
    let isInvited: Bool

    func body(content: Content) -> some View {
        if isInvited {
            content
                .opacity(0.6)  // Dim the image
                .overlay(
                    Circle()
                        .strokeBorder(
                            style: StrokeStyle(
                                lineWidth: 2,
                                dash: [5]
                            )
                        )
                        .foregroundColor(VivaDesign.Colors.vivaGreen)
                )
        } else {
            content
        }
    }
}
