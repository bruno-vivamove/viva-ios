import SwiftUI

struct VivaProfileImage: View {
    let imageUrl: String?
    let size: VivaDesign.Sizing.ProfileImage
    
    var body: some View {
        if let urlString = imageUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: size.rawValue, height: size.rawValue)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size.rawValue, height: size.rawValue)
                case .failure(let error):
                    defaultImage
                        .onAppear {
                            // More detailed error logging
                            print("🖼️ Image load failed:")
                            print("URL: \(urlString)")
                            print("Error: \(error)")
                            
                            // Cast error to NSError
                            let nsError = error as NSError
                            print("Domain: \(nsError.domain)")
                            print("Code: \(nsError.code)")
                            print("Description: \(nsError.localizedDescription)")
                            if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
                                print("Underlying error: \(underlyingError)")
                            }
                            
                            // Check if URL is reachable
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
                }
            }
            .clipShape(Circle())
        } else {
            defaultImage
                .clipShape(Circle())
        }
    }
    
    private var defaultImage: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .foregroundColor(.gray)
            .frame(width: size.rawValue, height: size.rawValue)
    }
}
