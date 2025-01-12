//
//  ProfileView.swift
//  Viva
//
//  Created by Bruno Souto on 1/9/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    // Sample user data
    private let user = User(
        id: "1",
        name: "Saya Jones",
        score: 3017,
        imageURL: "google_logo"
    )
    
    // Menu items data
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
        VStack(spacing: 32) {
            // Profile Header
            HStack(spacing: 30) {
                Spacer()
                VStack {
                    Image("profile_stock")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                    
                    Text(user.name)
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Button(action: {
                        // Add edit action
                    }) {
                        Text("Edit")
                            .font(.subheadline)
                            .foregroundColor(.vivaGreen)
                    }
                }
                
                VStack {
                    Text("\(user.score)")
                        .font(.system(size: 42))
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    
                    Text("Reward Points")
                        .font(.subheadline)
                        .foregroundColor(.vivaGreen)
                }
                Spacer()

            }
            .padding(.top)
            
            // Menu Items
            VStack(spacing: 8) {
                ForEach(menuItems, id: \.title) { item in
                    Button(action: {
                        // Add navigation action
                    }) {
                        HStack {
                            Image(systemName: item.icon)
                                .foregroundColor(.white)
                                .frame(width: 24)
                            
                            Text(item.title)
                                .foregroundColor(.white)
                                .font(.body)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 12) // Reduced vertical padding
                        .padding(.horizontal, 12) // Adjusted horizontal padding
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.6), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal)
            
            // Log Out Button
            Button(action: {
                authManager.signOut()
            }) {
                Text("LOG OUT")
                    .font(.headline)
                    .foregroundColor(.vivaGreen)
                    .padding(.vertical)
            }
            
            Spacer()
    }
        .background(Color.black)
    }
}

// Supporting struct for menu items
struct MenuItem {
    let icon: String
    let title: String
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
