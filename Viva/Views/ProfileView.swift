import SwiftUI

struct ProfileView: View {
    private let userSession: UserSession
    private let authManager: AuthenticationManager
    private let userProfileService: UserProfileService

    private let menuItems = [
        MenuItem(icon: "applewatch", title: "Linked Devices"),
        MenuItem(icon: "doc.text", title: "Rules & FAQ"),
        MenuItem(icon: "bell.fill", title: "Notifications"),
        MenuItem(icon: "gearshape.fill", title: "Settings"),
        MenuItem(icon: "person.2.fill", title: "Referrals"),
        MenuItem(icon: "star.fill", title: "Subscription"),
        MenuItem(icon: "questionmark.circle", title: "Help"),
    ]

    init(
        userSession: UserSession,
        authManager: AuthenticationManager,
        userProfileService: UserProfileService
    ) {
        self.userSession = userSession
        self.authManager = authManager
        self.userProfileService = userProfileService
    }

    var body: some View {
        VStack(spacing: VivaDesign.Spacing.large) {
            // Profile Header
            ProfileHeader(
                userSession: userSession,
                userProfileService: userProfileService)

            // Menu Items
            VStack(spacing: VivaDesign.Spacing.minimal) {
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

    private let userProfileService: UserProfileService

    init(
        userSession: UserSession,
        userProfileService: UserProfileService
    ) {
        self.userSession = userSession
        self.userProfileService = userProfileService
    }

    var body: some View {
        HStack(spacing: VivaDesign.Spacing.large) {
            Spacer()

            // Profile Image and Name
            VStack(spacing: VivaDesign.Spacing.minimal) {
                VivaProfileImage(
                    imageId: userSession.getUserProfile().imageUrl
                        ?? "profile_default",
                    size: .large
                )

                Text(userSession.getUserProfile().displayName)
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

            // Points Display
            VStack(spacing: VivaDesign.Spacing.minimal) {
                Text("\(userSession.getUserProfile().rewardPoints ?? 0)")
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
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(
                userSession: userSession, userProfileService: userProfileService
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

#Preview {
    let userSession = VivaAppObjects.dummyUserSession()
    let vivaAppObjects = VivaAppObjects(userSession: userSession)

    ProfileView(
        userSession: userSession,
        authManager: vivaAppObjects.authenticationManager,
        userProfileService: vivaAppObjects.userProfileService
    )
}
