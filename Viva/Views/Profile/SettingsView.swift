import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var userSession: UserSession
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var userService: UserService
    @EnvironmentObject var userProfileService: UserProfileService
    @Environment(\.presentationMode) var presentationMode

    private let menuItems = [
        MenuItem(icon: "applewatch", title: "Linked Devices"),
        MenuItem(icon: "doc.text", title: "Rules & FAQ"),
        MenuItem(icon: "bell.fill", title: "Notifications"),
        MenuItem(icon: "gearshape.fill", title: "Settings"),
        MenuItem(icon: "person.2.fill", title: "Referrals"),
        MenuItem(icon: "star.fill", title: "Subscription"),
        MenuItem(icon: "questionmark.circle", title: "Help"),
    ]

    var body: some View {
        VStack(spacing: VivaDesign.Spacing.large) {
            // Header with close button
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20))
                        .foregroundColor(VivaDesign.Colors.primaryText)
                        .padding()
                }
                
                Spacer()
                
                Text("Settings")
                    .font(.title2)
                    .foregroundColor(VivaDesign.Colors.primaryText)
                
                Spacer()
                
                // Empty view for balance
                Color.clear
                    .frame(width: 20, height: 20)
                    .padding()
            }
            
            // Profile Header
            ProfileHeader(
                userSession: userSession,
                userService: userService,
                userProfileService: userProfileService
            )

            // Menu Items
            VStack(spacing: VivaDesign.Spacing.xsmall) {
                ForEach(menuItems, id: \.title) { item in
                    MenuItemButton(item: item)
                }
            }
            .padding(.horizontal)

            Button(action: {
                Task {
                    await authManager.signOut()
                }
            }) {
                Text("LOG OUT")
                    .font(.headline)
                    .foregroundColor(VivaDesign.Colors.vivaGreen)
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
    @ObservedObject var userSession: UserSession
    @State private var showEditProfile = false

    private let userService: UserService
    private let userProfileService: UserProfileService

    init(
        userSession: UserSession,
        userService: UserService,
        userProfileService: UserProfileService
    ) {
        self.userSession = userSession
        self.userService = userService
        self.userProfileService = userProfileService
    }

    var body: some View {
        HStack(spacing: VivaDesign.Spacing.large) {
            Spacer()

            // Profile Image and Name
            VStack(spacing: VivaDesign.Spacing.xsmall) {
                Button(action: {
                    Task {
                        let userProfile = try await userProfileService.getCurrentUserProfile()
                        await MainActor.run() {
                            userSession.setUserProfile(userProfile)
                        }
                    }
                }) {
                    VivaProfileImage(
                        userId: userSession.userProfile?.userSummary.id,
                        imageUrl: userSession.userProfile?.userSummary.imageUrl,
                        size: .large
                    )
                }

                Text(userSession.userProfile?.userSummary.displayName ?? "")
                    .font(.title2)
                    .foregroundColor(VivaDesign.Colors.primaryText)

                Button(action: {
                    showEditProfile = true
                }) {
                    Text("Edit")
                        .font(VivaDesign.Typography.caption)
                        .foregroundColor(VivaDesign.Colors.vivaGreen)
                }
            }

            Spacer()
        }
        .padding(.top)
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(
                userSession: userSession, userService: userService
            )
        }
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
                    .stroke(
                        VivaDesign.Colors.divider,
                        lineWidth: VivaDesign.Sizing.borderWidth)
            )
        }
    }
}

struct MenuItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
}
