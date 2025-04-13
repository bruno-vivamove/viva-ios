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
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size.rawValue, height: size.rawValue)
                        .modifier(InvitedModifier(isInvited: isInvited))
                        .clipShape(Circle())
                case .empty:
                    defaultImage
                        .modifier(InvitedModifier(isInvited: isInvited))
                        .shimmering(
                            animation: VivaDesign.AnimationStyle.loadingShimmer)
                case .failure(let error):
                    defaultImage
                        .modifier(InvitedModifier(isInvited: isInvited))
                        .onAppear {
                            AppLogger.error("Image load failed for URL: \(url) - \(error)")
                        }
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
        let request = URLRequest(
            url: url, cachePolicy: .returnCacheDataElseLoad)

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
