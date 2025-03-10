import SkeletonView
import SwiftUI
import Combine

// Static image cache for sharing across all instances
final class ImageCacheManager {
    static let shared = ImageCacheManager()
    private var cache = NSCache<NSString, UIImage>()

    private init() {
        // Set limits on the cache
        cache.countLimit = 100
    }

    func get(for key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }

    func set(_ image: UIImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
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
        let gradient = SkeletonGradient(baseColor: UIColor.black, secondaryColor: UIColor.white)
        imageView.showAnimatedGradientSkeleton(usingGradient: gradient)

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

struct VivaProfileImage: View {
    let userId: String?
    let imageUrl: String?
    @State private var cachedImage: UIImage? = nil
    @State private var isLoading: Bool = true
    @State private var imageOpacity: Double = 0
    
    // Add cancellables set for Combine subscriptions
    @State private var cancellables = Set<AnyCancellable>()

    let size: VivaDesign.Sizing.ProfileImage
    let isInvited: Bool

    init(
        userId: String?,
        imageUrl: String?, size: VivaDesign.Sizing.ProfileImage,
        isInvited: Bool = false
    ) {
        self.userId = userId
        self.imageUrl = imageUrl
        self.size = size
        self.isInvited = isInvited
    }

    var body: some View {
        if let urlString = imageUrl, let url = URL(string: urlString) {
            ZStack {
                // Always show skeleton during loading
                if isLoading {
                    SkeletonProfileImageView(
                        size: size.rawValue, isInvited: isInvited
                    )
                    .frame(width: size.rawValue, height: size.rawValue)
                }

                // Show image with opacity animation when available
                if let cachedImage = cachedImage {
                    Image(uiImage: cachedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size.rawValue, height: size.rawValue)
                        .modifier(InvitedModifier(isInvited: isInvited))
                        .clipShape(Circle())
                        .opacity(imageOpacity)
                } else if !isLoading {
                    // Fallback to AsyncImage if cache failed but loading completed
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            // This should rarely show since we have the skeleton
                            SkeletonProfileImageView(
                                size: size.rawValue, isInvited: isInvited
                            )
                            .frame(width: size.rawValue, height: size.rawValue)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(
                                    width: size.rawValue, height: size.rawValue
                                )
                                .modifier(InvitedModifier(isInvited: isInvited))
                                .opacity(imageOpacity)
                                .onAppear {
                                    imageOpacity = 1.0
                                    isLoading = false
                                }
                        case .failure(let error):
                            defaultImage
                                .modifier(InvitedModifier(isInvited: isInvited))
                                .onAppear {
                                    print("🖼️ Image load failed:")
                                    print("URL: \(urlString)")
                                    print("Error: \(error)")

                                    let nsError = error as NSError
                                    print("Domain: \(nsError.domain)")
                                    print("Code: \(nsError.code)")
                                    print(
                                        "Description: \(nsError.localizedDescription)"
                                    )
                                    if let underlyingError = nsError.userInfo[
                                        NSUnderlyingErrorKey] as? Error
                                    {
                                        print(
                                            "Underlying error: \(underlyingError)"
                                        )
                                    }

                                    URLSession.shared.dataTask(with: url) {
                                        _, response, error in
                                        if let httpResponse = response
                                            as? HTTPURLResponse
                                        {
                                            print(
                                                "HTTP Status: \(httpResponse.statusCode)"
                                            )
                                            print(
                                                "Headers: \(httpResponse.allHeaderFields)"
                                            )
                                        }
                                        if let error = error {
                                            print("Network error: \(error)")
                                        }
                                    }.resume()
                                }
                        @unknown default:
                            defaultImage
                                .modifier(InvitedModifier(isInvited: isInvited))
                        }
                    }
                    .clipShape(Circle())
                }
            }
            .onAppear {
                // Reset states
                isLoading = true
                imageOpacity = 0

                // Check memory cache first for instant results
                if let memCachedImage = ImageCacheManager.shared.get(
                    for: urlString)
                {
                    self.cachedImage = memCachedImage
                    // Delay slightly to ensure UI is ready, then animate in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        imageOpacity = 1.0
                        isLoading = false
                    }
                } else {
                    // Check disk cache
                    checkCache(for: url, urlString: urlString)
                }

                // Subscribe to profile update notifications using Combine
                setupNotificationObserver()
            }
        } else {
            defaultImage
                .clipShape(Circle())
                .modifier(InvitedModifier(isInvited: isInvited))
        }
    }
    
    private func setupNotificationObserver() {
        // Clear any existing subscriptions to avoid duplicates
        cancellables.removeAll()
        
        // Subscribe to profile update notifications
        NotificationCenter.default.publisher(for: .userProfileUpdated)
            .compactMap { $0.object as? UserProfile }
            .filter { [userId] updatedProfile in
                // Only process notifications for this user
                guard let currentUserId = userId else { return false }
                return currentUserId == updatedProfile.id
            }
            .receive(on: DispatchQueue.main)
            .sink { updatedProfile in
                // Update the image URL
                //self.imageUrl = updatedProfile.imageUrl
                
                withAnimation {
                    self.imageOpacity = 0  // Fade out current image
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.cachedImage = nil  // Clear the cached image to force a reload
                    self.isLoading = true  // Show skeleton while loading
                    
                    // If we have a new URL, preload it
                    if let newUrlString = updatedProfile.imageUrl,
                       let newUrl = URL(string: newUrlString) {
                        checkCache(for: newUrl, urlString: newUrlString)
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func checkCache(for url: URL, urlString: String) {
        // Create a request with appropriate cache policy
        let request = URLRequest(
            url: url, cachePolicy: .returnCacheDataElseLoad)

        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    // Update memory cache for other instances to use
                    ImageCacheManager.shared.set(image, for: urlString)
                    self.cachedImage = image

                    // Animate the image in
                    withAnimation(.easeIn(duration: 0.3)) {
                        self.imageOpacity = 1.0
                        self.isLoading = false
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
        task.resume()
    }

    private var defaultImage: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .foregroundColor(.gray)
            .frame(width: size.rawValue, height: size.rawValue)
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
