import SwiftUI

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

struct VivaProfileImage: View {
    let userId: String?
    @State private var imageUrl: String?
    let size: VivaDesign.Sizing.ProfileImage
    let isInvited: Bool
    @State private var cachedImage: UIImage? = nil

    init(
        userId: String?,
        imageUrl: String?, size: VivaDesign.Sizing.ProfileImage,
        isInvited: Bool = false
    ) {
        self.userId = userId
        self._imageUrl = State(initialValue: imageUrl)
        self.size = size
        self.isInvited = isInvited
    }

    var body: some View {
        if let urlString = imageUrl, let url = URL(string: urlString) {
            ZStack {
                // If we have a cached image, show it immediately
                if let cachedImage = cachedImage {
                    Image(uiImage: cachedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size.rawValue, height: size.rawValue)
                        .modifier(InvitedModifier(isInvited: isInvited))
                        .clipShape(Circle())
                } else {
                    // Otherwise, use AsyncImage as a fallback
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(
                                    width: size.rawValue, height: size.rawValue
                                )
                                .modifier(InvitedModifier(isInvited: isInvited))
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(
                                    width: size.rawValue, height: size.rawValue
                                )
                                .modifier(InvitedModifier(isInvited: isInvited))
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
                // Check memory cache first for instant results
                if let memCachedImage = ImageCacheManager.shared.get(
                    for: urlString)
                {
                    self.cachedImage = memCachedImage
                } else {
                    // Check disk cache
                    checkCache(for: url, urlString: urlString)
                }
                
                // Subscribe to profile update notifications
                NotificationCenter.default.addObserver(
                    forName: .userProfileUpdated,
                    object: nil,
                    queue: .main
                ) { [userId] notification in
                    guard let updatedProfile = notification.object as? UserProfile,
                          let currentUserId = userId,
                          currentUserId == updatedProfile.id else { return }
                    
                    // If this is the user whose profile was updated, update the image URL
                    self.imageUrl = updatedProfile.imageUrl
                    self.cachedImage = nil // Clear the cached image to force a reload
                    
                    // If we have a new URL, preload it
                    if let newUrlString = updatedProfile.imageUrl,
                       let newUrl = URL(string: newUrlString) {
                        checkCache(for: newUrl, urlString: newUrlString)
                    }
                }
            }
            .onDisappear {
                // Unsubscribe when view disappears
                NotificationCenter.default.removeObserver(
                    self,
                    name: .userProfileUpdated,
                    object: nil
                )
            }
        } else {
            defaultImage
                .clipShape(Circle())
                .modifier(InvitedModifier(isInvited: isInvited))
        }
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
