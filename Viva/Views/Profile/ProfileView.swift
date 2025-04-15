import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userSession: UserSession
    @EnvironmentObject var userProfileService: UserProfileService
    @EnvironmentObject var matchupService: MatchupService
    @EnvironmentObject var userMeasurementService: UserMeasurementService
    @EnvironmentObject var healthKitDataManager: HealthKitDataManager
    @EnvironmentObject var friendService: FriendService
    @EnvironmentObject var userService: UserService

    @StateObject private var viewModel: ProfileViewModel
    @State private var showSettings = false
    @State private var showEditProfile = false
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?

    init(viewModel: ProfileViewModel) {
        // Note: This will be properly initialized when the view is created since the required services are provided as environment objects
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Black background
                Color.black
                    .edgesIgnoringSafeArea(.all)

                // Scrollable content
                ScrollView(.vertical, showsIndicators: false) {
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: ViewOffsetKey.self,
                            value: geometry.frame(in: .named("scroll")).origin)
                    }
                    .frame(height: 0)

                    VStack(spacing: 0) {
                        // Top section with profile image and aligned elements
                        // Using ZStack to position gray area behind content
                        ZStack(alignment: .top) {
                            // Gray area with warp_speed image
                            Image("warp_speed")
                                .resizable()
                                .frame(height: 200)
                                .background(
                                    Color(
                                        red: 35 / 255, green: 35 / 255,
                                        blue: 35 / 255)
                                )
                                .offset(y: 0)

                            VStack(alignment: .leading, spacing: 12) {
                                // Add significant top padding to move content down
                                Spacer()
                                    .frame(height: 75)

                                // Profile image and streak in same row
                                HStack(alignment: .bottom, spacing: 32) {
                                    // Profile image (left aligned)
                                    ZStack(alignment: .bottomTrailing) {
                                        // Profile image with skeleton loading built in
                                        VivaProfileImage(
                                            userId: userSession.userProfile?.id,
                                            imageUrl: userSession.userProfile?.imageUrl,
                                            size: .xlarge
                                        )
                                        .padding(.top, 16)
                                        .opacity(viewModel.isImageLoading ? 0.6 : 1)

                                        // Plus button for editing profile picture
                                        Button(action: {
                                            showImagePicker = true
                                        }) {
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 30, height: 30)
                                                .overlay(
                                                    Image(systemName: "plus")
                                                        .foregroundColor(.black)
                                                        .font(
                                                            .system(
                                                                size: 24,
                                                                weight: .bold))
                                                )
                                        }
                                        .offset(x: -4, y: -4)
                                        .disabled(viewModel.isImageLoading)
                                    }

                                    // Streak counter next to profile image
                                    ZStack(alignment: .bottom) {
                                        Circle()
                                            .stroke(
                                                VivaDesign.Colors.vivaGreen,
                                                lineWidth: 1
                                            )
                                            .frame(width: 44, height: 44)

                                        Text("9")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.white)
                                            .offset(y: -10)

                                        Image(systemName: "bolt.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                            .offset(x: 14, y: -30)

                                        Text("Streak")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white)
                                            .offset(y: 20)
                                    }

                                    Spacer()

                                    // Hamburger menu button
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
                                Text(userSession.userProfile?.displayName ?? "")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)

                                // Location (left aligned)
                                HStack(spacing: 6) {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(
                                            VivaDesign.Colors.vivaGreen
                                        )
                                        .font(.system(size: 14))

                                    Text("New York, NY")
                                        .font(.system(size: 16))
                                        .foregroundColor(
                                            VivaDesign.Colors.vivaGreen)
                                }
                                .padding(.top, 2)
                                .padding(.horizontal, 16)

                                // Edit Profile Button (left aligned)
                                Button(action: {
                                    showEditProfile = true
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

                                // User caption
                                if let caption = userSession.userProfile?.caption, !caption.isEmpty
                                {
                                    Text(caption)
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(4)
                                        .padding(.horizontal, 16)
                                        .padding(.top, 8)
                                }

                                // Stats row
                                HStack(alignment: .top, spacing: 0) {
                                    Spacer()

                                    StatItem(
                                        value: "90", label: "Matchups",
                                        iconName: "person.2.fill")

                                    Spacer()

                                    StatItem(
                                        value: "221", label: "Workouts",
                                        iconName: "figure.run")

                                    Spacer()

                                    StatItem(
                                        value: "3.9K", label: "Minutes",
                                        iconName: "clock.fill")

                                    Spacer()

                                    StatItem(
                                        value: "11.3k", label: "Calories",
                                        iconName: "flame.fill")

                                    Spacer()

                                    StatItem(
                                        value: "2.1K", label: "Cheers",
                                        iconName: "hand.thumbsup.fill")

                                    Spacer()
                                }
                                .padding(.top, 32)
                            }
                        }

                        Divider()
                            .background(Color.gray.opacity(0.6))
                            .padding(VivaDesign.Spacing.medium)

                        // Active Matchups section
                        if !viewModel.activeMatchups.isEmpty {
                            MatchupSectionView(
                                title: "Active Matchups",
                                matchups: viewModel.activeMatchups,
                                lastRefreshTime: nil,
                                onMatchupSelected: { matchup in
                                    viewModel.selectMatchup(matchup)
                                },
                                matchupService: matchupService,
                                healthKitDataManager: healthKitDataManager,
                                userSession: userSession,
                                userMeasurementService: userMeasurementService
                            )
                            .padding(.horizontal, 16)
                        } else {
                            VStack {
                                Text("No Active Matchups")
                                    .font(VivaDesign.Typography.title3)
                                    .foregroundColor(.gray)
                                    .padding(.vertical, 20)
                            }
                            .padding(.horizontal, 16)
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
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(
                    userSession: userSession, userProfileService: userProfileService
                )
            }
            .sheet(isPresented: $showImagePicker, onDismiss: {
                if let selectedImage = selectedImage {
                    viewModel.saveProfileImage(selectedImage)
                }
            }) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .navigationDestination(item: $viewModel.selectedMatchup) { matchup in
                MatchupDetailView(
                    viewModel: MatchupDetailViewModel(
                        matchupId: matchup.id,
                        matchupService: matchupService,
                        userMeasurementService: userMeasurementService,
                        friendService: friendService,
                        userService: userService,
                        userSession: userSession,
                        healthKitDataManager: healthKitDataManager
                    ),
                    source: "profile"
                )
            }
            .edgesIgnoringSafeArea(.top)
            .alert(item: errorMessageBinding) { message in
                Alert(
                    title: Text("Error"),
                    message: Text(message.text),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                Task {
                    await viewModel.loadActiveMatchups()
                }
            }
        }
    }
    
    // Helper struct to wrap error messages for the alert API
    struct ErrorMessage: Identifiable {
        let id = UUID()
        let text: String
    }
    
    private var errorMessageBinding: Binding<ErrorMessage?> {
        Binding<ErrorMessage?>(
            get: {
                viewModel.errorMessage.map { ErrorMessage(text: $0) }
            },
            set: { _ in
                viewModel.errorMessage = nil
            }
        )
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
        VStack(spacing: 0) {
            // Circled value
            ZStack {
                Circle()
                    .stroke(VivaDesign.Colors.vivaGreen, lineWidth: 1)
                    .frame(width: 60, height: 60)

                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }

            // Icon and label positioned to overlap with bottom of circle
            VStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.system(size: 16))
                    .foregroundColor(.white)

                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            }
            .offset(y: -10)
        }
        .frame(width: 60)
    }
}
