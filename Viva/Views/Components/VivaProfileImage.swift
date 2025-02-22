import SwiftUI

struct VivaProfileImage: View {
    let imageUrl: String?
    let size: VivaDesign.Sizing.ProfileImage
    let isInvited: Bool
    
    init(imageUrl: String?, size: VivaDesign.Sizing.ProfileImage, isInvited: Bool = false) {
        self.imageUrl = imageUrl
        self.size = size
        self.isInvited = isInvited
    }
    
    var body: some View {
        if let urlString = imageUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: size.rawValue, height: size.rawValue)
                        .modifier(InvitedModifier(isInvited: isInvited))
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size.rawValue, height: size.rawValue)
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
                            print("Description: \(nsError.localizedDescription)")
                            if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
                                print("Underlying error: \(underlyingError)")
                            }
                            
                            URLSession.shared.dataTask(with: url) { _, response, error in
                                if let httpResponse = response as? HTTPURLResponse {
                                    print("HTTP Status: \(httpResponse.statusCode)")
                                    print("Headers: \(httpResponse.allHeaderFields)")
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
