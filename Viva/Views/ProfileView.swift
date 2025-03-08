import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userSession: UserSession
    @EnvironmentObject var userProfileService: UserProfileService
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            // Black background
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            // Scrollable content
            ScrollView(.vertical, showsIndicators: false) {
                GeometryReader { geometry in
                    Color.clear.preference(key: ViewOffsetKey.self, value: geometry.frame(in: .named("scroll")).origin)
                }
                .frame(height: 0)
                
                VStack(spacing: 0) {
                    // Top section with profile image and aligned elements
                    // Using ZStack to position gray area behind content
                    ZStack(alignment: .top) {
                        // Gray area at the top that scrolls with content
                        Rectangle()
                            .fill(Color(red: 35/255, green: 35/255, blue: 35/255))
                            .frame(height: 200)
                            .offset(y: 0)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            // Add significant top padding to move content down
                            Spacer()
                                .frame(height: 75)
                        
                        // Profile image and streak in same row
                        HStack(alignment: .bottom, spacing: 32) {
                            // Profile image (left aligned)
                            ZStack(alignment: .bottomTrailing) {
                                VivaProfileImage(
                                    imageUrl: userSession.getUserProfile().imageUrl,
                                    size: .xlarge
                                )
                                .padding(.top, 16)
                                
                                // Plus button for editing profile picture
                                Button(action: {
                                    // Action to change profile picture
                                }) {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Image(systemName: "plus")
                                                .foregroundColor(.black)
                                                .font(.system(size: 24, weight: .bold))
                                        )
                                }
                                .offset(x: -4, y: -4)
                            }
                            
                            // Streak counter next to profile image
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .stroke(VivaDesign.Colors.vivaGreen, lineWidth: 1)
                                        .frame(width: 44, height: 44)
                                    
                                    Text("9")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    // Lightning bolt in top right
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                        .offset(x: 14, y: -14)
                                }
                                
                                Text("Streak")
                                    .font(.system(size: 10))
                                    .foregroundColor(VivaDesign.Colors.vivaGreen)
                            }
                            
                            Spacer()
                            
                            // Hamburger menu button positioned in the HStack to align with profile image
                            Button(action: {
                                showSettings = true
                            }) {
                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                                    .padding(.trailing, 16)
                            }
                        }
                        .padding(.top, 16)
                        .padding(.horizontal, 16)
                        
                        // User name (left aligned)
                        Text(userSession.getUserProfile().displayName)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                        
                        // Location (left aligned)
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(VivaDesign.Colors.vivaGreen)
                                .font(.system(size: 14))
                            
                            Text("New York, NY")
                                .font(.system(size: 16))
                                .foregroundColor(VivaDesign.Colors.vivaGreen)
                        }
                        .padding(.top, 2)
                        .padding(.horizontal, 16)
                        
                        // Edit Profile Button (left aligned)
                        Button(action: {
                            // Action to edit profile
                        }) {
                            HStack(spacing: 6) {
                                Text("Edit Profile")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                
                                Image(systemName: "pencil")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            }
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 16)
                        
                        // User Bio (left aligned)
                        Text("Former D1 soccer player, 2x marathon finisher, strength training is my sanctuary")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        
                        // Stats row
                        HStack(alignment: .top, spacing: 0) {
                            Spacer()
                            
                            StatItem(value: "90", label: "Matchups", iconName: "person.2.fill")
                            
                            Spacer()
                            
                            StatItem(value: "221", label: "Workouts", iconName: "figure.run")
                            
                            Spacer()
                            
                            StatItem(value: "3.9K", label: "Minutes", iconName: "clock.fill")
                            
                            Spacer()
                            
                            StatItem(value: "11.3k", label: "Calories", iconName: "flame.fill")
                            
                            Spacer()
                            
                            StatItem(value: "2.1K", label: "Cheers", iconName: "hand.thumbsup.fill")
                            
                            Spacer()
                        }
                        .padding(.top, 32)
                        }
                    }
                    
                    Divider()
                        .background(Color.gray.opacity(0.6))
                        .padding(.top, 32)
                    
                    // Trophy case section
                    VStack(spacing: 8) {
                        HStack {
                            Text("Trophy case")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: {
                                // Action to view all trophies
                            }) {
                                Text("View all")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .opacity(0.7)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        
                        // Sample trophies (placeholder)
                        HStack(spacing: 20) {
                            ForEach(0..<3) { _ in
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 80, height: 80)
                            }
                        }
                        .padding(.vertical, 20)
                    }
                    
                    // Add some padding at the bottom for scrolling
                    Spacer()
                        .frame(height: 40)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .edgesIgnoringSafeArea(.top)
    }
}

// ViewOffsetKey for tracking scroll position
struct ViewOffsetKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        value = nextValue()
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let iconName: String
    
    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Image(systemName: iconName)
                .font(.system(size: 16))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white)
        }
        .frame(width: 60)
    }
}
