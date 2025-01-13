import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    private let user = User(
        id: "1",
        name: "Saya Jones",
        score: 3017,
        imageURL: "profile_stock"
    )
    
    private let menuItems = [
        MenuItem(icon: "applewatch", title: "Linked Devices"),
        MenuItem(icon: "doc.text", title: "Rules & FAQ"),
        MenuItem(icon: "bell.fill", title: "Notifications"),
        MenuItem(icon: "gearshape.fill", title: "Settings"),
        MenuItem(icon: "person.2.fill", title: "Referrals"),
        MenuItem(icon: "star.fill", title: "Subscription"),
        MenuItem(icon: "questionmark.circle", title: "Help")
    ]
    
    var body: some View {
        VStack(spacing: VivaDesign.Spacing.large) {
            // Profile Header
            ProfileHeader(user: user)
            
            // Menu Items
            VStack(spacing: VivaDesign.Spacing.minimal) {
                ForEach(menuItems, id: \.title) { item in
                    MenuItemButton(item: item)
                }
            }
            .padding(.horizontal)
                        
            Button(action: {
                authManager.signOut()
            }) {
                Text("LOG OUT")
                    .font(.headline)
                    .foregroundColor(.vivaGreen)
                    .padding(.vertical)
            }
            .padding(.horizontal)
            Spacer()
        }
        .padding(.vertical, VivaDesign.Spacing.medium)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VivaDesign.Colors.background)
    }
}

struct ProfileHeader: View {
    let user: User
    
    var body: some View {
        HStack(spacing: VivaDesign.Spacing.large) {
            Spacer()
            
            // Profile Image and Name
            VStack(spacing: VivaDesign.Spacing.minimal) {
                VivaProfileImage(
                    imageURL: user.imageURL,
                    size: .large
                )
                
                Text(user.name)
                    .font(.title2)
                    .foregroundColor(VivaDesign.Colors.primaryText)
                
                Button(action: {
                    // Add edit action
                }) {
                    Text("Edit")
                        .font(VivaDesign.Typography.caption)
                        .foregroundColor(VivaDesign.Colors.vivaGreen)
                }
            }
            
            // Points Display
            VStack(spacing: VivaDesign.Spacing.minimal) {
                Text("\(user.score)")
                    .font(VivaDesign.Typography.displayText(42))
                    .foregroundColor(VivaDesign.Colors.primaryText)
                    .fontWeight(.bold)
                
                Text("Reward Points")
                    .font(VivaDesign.Typography.caption)
                    .foregroundColor(VivaDesign.Colors.vivaGreen)
            }
            
            Spacer()
        }
        .padding(.top)
    }
}

struct MenuItemButton: View {
    let item: MenuItem
    
    var body: some View {
        Button(action: {
            // Add navigation action
        }) {
            HStack {
                Image(systemName: item.icon)
                    .foregroundColor(VivaDesign.Colors.primaryText)
                    .frame(width: 24)
                
                Text(item.title)
                    .foregroundColor(VivaDesign.Colors.primaryText)
                    .font(VivaDesign.Typography.body)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(VivaDesign.Colors.secondaryText)
            }
            .padding(.vertical, VivaDesign.Spacing.small)
            .padding(.horizontal, VivaDesign.Spacing.small)
            .background(
                RoundedRectangle(cornerRadius: VivaDesign.Sizing.cornerRadius)
                    .stroke(VivaDesign.Colors.divider, lineWidth: VivaDesign.Sizing.borderWidth)
            )
        }
    }
}

struct MenuItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
}


#Preview {
    ProfileView()
        .environmentObject(AuthenticationManager())
}

