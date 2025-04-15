import SwiftUI
import NukeUI
import Nuke

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
            LazyImage(url: url) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size.rawValue, height: size.rawValue)
                        .modifier(InvitedModifier(isInvited: isInvited))
                        .clipShape(Circle())
                } else if state.error != nil {
                    defaultImage
                        .modifier(InvitedModifier(isInvited: isInvited))
                        .onAppear {
                            if let error = state.error {
                                AppLogger.error(
                                    "Image load failed for URL: \(url) - \(error)"
                                )
                            }
                        }
                } else {
                    defaultImage
                        .modifier(InvitedModifier(isInvited: isInvited))
                        .shimmering(
                            animation: VivaDesign.AnimationStyle.loadingShimmer
                        )
                }
            }
            .priority(.normal)
            .processors([ImageProcessors.Resize(size: CGSize(width: size.rawValue, height: size.rawValue))])
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
