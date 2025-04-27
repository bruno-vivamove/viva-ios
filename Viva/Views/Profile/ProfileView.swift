import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userSession: UserSession
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

        // Make navigation bar transparent
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        ZStack {
            // Black background
            Color.black
                .edgesIgnoringSafeArea(.all)

            // Scrollable content
            ScrollView(.vertical, showsIndicators: false) {
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: ViewOffsetKey.self,
                        value: geometry.frame(in: .named("scroll")).origin
                    )
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
                                    red: 35 / 255,
                                    green: 35 / 255,
                                    blue: 35 / 255
                                )
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
                                        userId: viewModel.userProfile?
                                            .userSummary.id,
                                        imageUrl: viewModel.userProfile?
                                            .userSummary.imageUrl,
                                        size: .xlarge
                                    )
                                    .padding(.top, 16)
                                    .opacity(
                                        viewModel.isImageLoading ? 0.6 : 1
                                    )

                                    // Plus button for editing profile picture - only for current user
                                    if viewModel.isCurrentUser {
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
                                                                weight: .bold
                                                            )
                                                        )
                                                )
                                        }
                                        .offset(x: -4, y: -4)
                                        .disabled(viewModel.isImageLoading)
                                    }
                                }

                                Spacer()

                                // Hamburger menu button - only for current user
                                if viewModel.isCurrentUser {
                                    Button(action: {
                                        showSettings = true
                                    }) {
                                        Image(systemName: "line.3.horizontal")
                                            .font(.system(size: 30))
                                            .foregroundColor(.white)
                                            .padding(.trailing, 16)
                                    }
                                }
                            }
                            .padding(.top, 16)
                            .padding(.horizontal, 16)

                            // User name (left aligned)
                            Text(
                                viewModel.userProfile?.userSummary.displayName
                                    ?? ""
                            )
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
                                        VivaDesign.Colors.vivaGreen
                                    )
                            }
                            .padding(.top, 2)
                            .padding(.horizontal, 16)

                            // Edit Profile Button (left aligned) - only for current user
                            if viewModel.isCurrentUser {
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
                            }

                            // User caption
                            if let caption = viewModel.userProfile?.userSummary
                                .caption, !caption.isEmpty
                            {
                                Text(caption)
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(4)
                                    .padding(.horizontal, 16)
                                    .padding(.top, VivaDesign.Spacing.xsmall)
                            }

                            // Stats row
                            GeometryReader { geo in
                                let userStats = viewModel.userProfile?.userStats
                                HStack(alignment: .top, spacing: 0) {
                                    Spacer()

                                    StatItem(
                                        value: "\(userStats?.wins ?? 0)",
                                        label: "Wins",
                                        iconName: "medal.fill",
                                        size: min(
                                            geo.size.width * 0.25,
                                            100
                                        )
                                    )

                                    Spacer()

                                    StatItem(
                                        value:
                                            "\(userStats?.totalElevatedHeartRate ?? 0)",
                                        label: "Move Mins",
                                        iconName: "figure.run",
                                        size: min(
                                            geo.size.width * 0.25,
                                            100
                                        )
                                    )

                                    Spacer()

                                    StatItem(
                                        value:
                                            "\(userStats?.totalEnergyBurned ?? 0)",
                                        label: "Active Cals",
                                        iconName: "flame.fill",
                                        size: min(
                                            geo.size.width * 0.25,
                                            100
                                        )
                                    )

                                    Spacer()
                                }
                                .frame(width: geo.size.width)
                            }
                            .frame(height: 120)
                            .padding(.top, VivaDesign.Spacing.medium)
                            .padding(
                                .bottom,
                                VivaDesign.Spacing.large
                            )
                        }
                    }

                    VivaDivider()
                        .padding(.bottom, VivaDesign.Spacing.medium)
                        .padding(
                            .horizontal,
                            VivaDesign.Spacing.outerPadding
                        )

                    // Active Matchups section - only show for current user
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
                        .padding(
                            .horizontal,
                            VivaDesign.Spacing.outerPadding
                        )
                    } else {
                        Text("No Active Matchups")
                            .font(VivaDesign.Typography.title3)
                            .foregroundColor(.gray)
                            .padding(.vertical, 20)
                            .padding(
                                .horizontal,
                                VivaDesign.Spacing.outerPadding
                            )
                    }

                    // Add some padding at the bottom for scrolling
                    Spacer()
                        .frame(height: 40)
                }
            }
            .ignoresSafeArea(edges: .top)
            .refreshable {
                await viewModel.loadData()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                EmptyView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(
                userSession: userSession,
                userService: userService
            )
        }
        .sheet(
            isPresented: $showImagePicker,
            onDismiss: {
                if let selectedImage = selectedImage {
                    viewModel.saveProfileImage(selectedImage)
                }
            }
        ) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .navigationDestination(item: $viewModel.selectedMatchup) {
            matchup in
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
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error.localizedDescription)
            }
        }
        .task {
            await viewModel.loadInitialDataIfNeeded()
        }
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
    let size: CGFloat

    init(value: String, label: String, iconName: String, size: CGFloat = 60) {
        self.value = value
        self.label = label
        self.iconName = iconName
        self.size = size
    }

    private var formattedValue: String {
        if let intValue = Int(value), intValue >= 1000 {
            let floatValue = Float(intValue) / 1000.0
            return String(format: "%.1fK", floatValue)
        }
        return value
    }

    var body: some View {
        VStack(spacing: 0) {
            // Concentric circles
            ZStack {
                // Outer circle with glow
                Circle()
                    .stroke(
                        VivaDesign.Colors.primaryText.opacity(0.3),
                        lineWidth: 5
                    )
                    .frame(width: size, height: size)
                    .blur(radius: 3)

                // Outer circle (crisp version on top of glow)
                Circle()
                    .stroke(
                        VivaDesign.Colors.primaryText.opacity(0.3),
                        lineWidth: 1
                    )
                    .fill(.black)
                    .frame(width: size, height: size)

                // Middle circle
                Circle()
                    .stroke(
                        VivaDesign.Colors.primaryText.opacity(0.3),
                        lineWidth: 1
                    )
                    .frame(width: size - 10, height: size - 10)

                // Inner circle
                Circle()
                    .stroke(
                        VivaDesign.Colors.primaryText.opacity(0.3),
                        lineWidth: 1
                    )
                    .frame(width: size - 20, height: size - 20)

                Text(formattedValue)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }

            // Icon and label positioned to overlap with bottom of circle
            VStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundColor(.white)

                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            .offset(y: -20)
        }
        .frame(width: size)
    }
}
