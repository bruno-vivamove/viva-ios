import Charts
import Lottie
import SwiftUI

struct WorkoutEntry: Identifiable {
    let id = UUID()
    let user: String
    let type: String
    let calories: Int
}

struct DailyActivity: Identifiable {
    let id = UUID()
    let day: String
    let value: Int
    let total: Int
}

struct MatchupDetailView: View {
    // Add skeleton opacity constant
    private let skeletonOpacity: Double = 1.0

    // Environment dependencies
    @EnvironmentObject var userSession: UserSession
    @EnvironmentObject var matchupService: MatchupService
    @EnvironmentObject var userMeasurementService: UserMeasurementService
    @EnvironmentObject var friendService: FriendService
    @EnvironmentObject var userService: UserService
    @EnvironmentObject var healthKitDataManager: HealthKitDataManager

    @State private var viewModel: MatchupDetailViewModel?
    @State private var isShowingTotal = true
    @State private var showUnInviteSheet = false
    @State private var selectedInvite: MatchupInvite? = nil
    @State private var selectedUserId: String? = nil
    @State private var navigateToProfile = false
    private let matchupId: String
    private let source: String
    @Environment(\.dismiss) private var dismiss

    init(
        matchupId: String,
        source: String
    ) {
        self.matchupId = matchupId
        self.source = source
    }

    var body: some View {
        ZStack {
            VivaDesign.Colors.background.edgesIgnoringSafeArea(.all)

            // Main content
            Group {
                if let viewModel = viewModel {
                    MatchupDetailContent(
                        viewModel: viewModel,
                        isShowingTotal: $isShowingTotal,
                        selectedInvite: $selectedInvite,
                        showUnInviteSheet: $showUnInviteSheet,
                        selectedUserId: $selectedUserId,
                        source: source
                    )
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }

            // Overlay for trophy animation when completed but not finalized
            if let viewModel = viewModel, viewModel.isCompletedButNotFinalized {
                Color.black.opacity(0.85)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: VivaDesign.Spacing.large) {
                    LottieView(animation: .named("trophy_plain"))
                        .playing(
                            .fromProgress(
                                0,
                                toProgress: 0.9,
                                loopMode: .playOnce
                            )
                        )
                        .frame(width: 200, height: 200)

                    Text("Congratulations!")
                        .font(.title.bold())
                        .foregroundColor(VivaDesign.Colors.vivaGreen)
                        .vivaText()

                    Text("Matchup Completed")
                        .font(.title3)
                        .foregroundColor(VivaDesign.Colors.primaryText)
                        .vivaText()

                    Button {
                        // Dismiss the overlay by setting isCompletedButNotFinalized to false
                        withAnimation(.easeInOut(duration: 0.5)) {
                            viewModel.isCompletedButNotFinalized = false
                        }
                    } label: {
                        Text("See Results")
                            .font(.headline)
                            .foregroundColor(.black)
                            .vivaText()
                            .padding(.horizontal, 40)
                            .padding(.vertical, 12)
                            .background(VivaDesign.Colors.vivaGreen)
                            .cornerRadius(8)
                    }
                    .padding(.top, VivaDesign.Spacing.medium)
                }
            }

            // Overlay for uninvite dialog
            if showUnInviteSheet, let user = selectedInvite?.user,
                let invite = selectedInvite
            {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showUnInviteSheet = false
                        }
                        selectedInvite = nil
                    }

                if let viewModel = viewModel {
                    InviteDialog(
                        viewModel: viewModel,
                        showUnInviteSheet: $showUnInviteSheet,
                        selectedInvite: $selectedInvite,
                        selectedUserId: $selectedUserId,
                        user: user,
                        inviteCode: invite.inviteCode
                    )
                }
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { selectedUserId != nil },
            set: { if !$0 { selectedUserId = nil } }
        )) {
            if let userId = selectedUserId {
                ProfileView(
                    userId: userId,
                    userSession: userSession,
                    userService: userService,
                    matchupService: matchupService
                )
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = MatchupDetailViewModel(
                    matchupId: matchupId,
                    matchupService: matchupService,
                    userMeasurementService: userMeasurementService,
                    friendService: friendService,
                    userService: userService,
                    userSession: userSession,
                    healthKitDataManager: healthKitDataManager
                )
            }
        }
        .task {
            if let viewModel = viewModel {
                await viewModel.loadInitialDataIfNeeded()
            }
        }
        .alert("Error", isPresented: .constant(viewModel?.error != nil)) {
            Button("OK") {
                viewModel?.error = nil
            }
        } message: {
            if let error = viewModel?.error {
                if let vivaError = error as? VivaErrorResponse {
                    Text(vivaError.message)
                } else {
                    Text(error.localizedDescription)
                }
            }
        }
        .toolbarBackground(VivaDesign.Colors.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark)
        .onChange(of: selectedUserId) { oldValue, newValue in
            navigateToProfile = newValue != nil
        }
    }

    // MARK: - Skeleton Loading View

    private var skeletonView: some View {
        VStack(spacing: 0) {
            // Scrollable skeleton content
            List {
                VStack(spacing: VivaDesign.Spacing.medium) {
                    // Header skeleton
                    skeletonHeader
                        .padding(.horizontal, VivaDesign.Spacing.screenPadding)
                        .padding(.top, VivaDesign.Spacing.medium)

                    // Toggle skeleton
                    skeletonToggle

                    // Comparison rows skeleton
                    VStack(spacing: VivaDesign.Spacing.medium) {
                        ForEach(0..<5, id: \.self) { _ in
                            skeletonComparisonRow
                        }
                    }
                    .padding(.horizontal, VivaDesign.Spacing.screenPadding)
                }
                .listRowBackground(VivaDesign.Colors.surface)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
                
                // Add empty space at the bottom for footer
                Color.clear
                    .frame(height: 100)
                    .listRowBackground(VivaDesign.Colors.surface)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
            }
            .listStyle(PlainListStyle())
            .scrollContentBackground(.hidden)

            // Footer skeleton
            skeletonFooter
                .padding(.horizontal, VivaDesign.Spacing.screenPadding)
                .padding(.vertical, VivaDesign.Spacing.medium)
                .background(VivaDesign.Colors.surface)
        }
        .shimmering(animation: VivaDesign.Animation.loadingShimmer)
    }

    private var skeletonHeader: some View {
        let placeholderColor = Color.gray.opacity(skeletonOpacity)

        return HStack(spacing: 0) {
            // Left user
            HStack(alignment: .center, spacing: 0) {
                // Profile image placeholder
                Circle()
                    .fill(placeholderColor)
                    .frame(
                        width: VivaDesign.Sizing.ProfileImage.large.rawValue,
                        height: VivaDesign.Sizing.ProfileImage.large.rawValue
                    )

                // Username and points placeholders
                VStack(alignment: .center) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(placeholderColor)
                        .frame(width: 60, height: 10)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(placeholderColor)
                        .frame(width: 40, height: 18)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)

            // Right user
            HStack(alignment: .center, spacing: 0) {
                // Username and points placeholders
                VStack(alignment: .center) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(placeholderColor)
                        .frame(width: 60, height: 10)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(placeholderColor)
                        .frame(width: 40, height: 18)
                }
                .frame(maxWidth: .infinity)

                // Profile image placeholder
                Circle()
                    .fill(placeholderColor)
                    .frame(
                        width: VivaDesign.Sizing.ProfileImage.large.rawValue,
                        height: VivaDesign.Sizing.ProfileImage.large.rawValue
                    )
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 60)
    }

    private var skeletonToggle: some View {
        let placeholderColor = Color.gray.opacity(skeletonOpacity)

        return HStack(spacing: VivaDesign.Spacing.medium) {
            // Left line
            Rectangle()
                .fill(placeholderColor)
                .frame(height: 1)
                .padding(.leading, VivaDesign.Spacing.small)

            // Toggle placeholder
            RoundedRectangle(cornerRadius: 2)
                .fill(placeholderColor)
                .frame(width: 120, height: 20)

            // Right line
            Rectangle()
                .fill(placeholderColor)
                .frame(height: 1)
                .padding(.trailing, VivaDesign.Spacing.small)
        }
    }

    private var skeletonComparisonRow: some View {
        let placeholderColor = Color.gray.opacity(skeletonOpacity)

        return VStack {
            HStack {
                Spacer()
                    .frame(width: VivaDesign.Spacing.medium)

                // Left side placeholders
                VStack(alignment: .center) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(placeholderColor)
                        .frame(width: 40, height: 24)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(placeholderColor)
                        .frame(width: 60, height: 12)
                }
                .frame(width: 80, alignment: .center)

                Spacer()

                // Center title placeholder
                RoundedRectangle(cornerRadius: 2)
                    .fill(placeholderColor)
                    .frame(width: 100, height: 14)
                    .frame(width: 140, alignment: .center)

                Spacer()

                // Right side placeholders
                VStack(alignment: .center) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(placeholderColor)
                        .frame(width: 40, height: 24)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(placeholderColor)
                        .frame(width: 60, height: 12)
                }
                .frame(width: 80, alignment: .center)

                Spacer()
                    .frame(width: VivaDesign.Spacing.medium)
            }

            // Divider placeholder
            VivaDivider()
                .padding(.top, VivaDesign.Spacing.small)
        }
    }

    private var skeletonFooter: some View {
        let placeholderColor = Color.gray.opacity(skeletonOpacity)

        return HStack {
            // Left section
            VStack(spacing: VivaDesign.Spacing.small) {
                // "Matchup Ends" label placeholder
                RoundedRectangle(cornerRadius: 2)
                    .fill(placeholderColor)
                    .frame(width: 80, height: 10)
                    .frame(maxWidth: .infinity, alignment: .center)

                // Time remaining placeholder
                RoundedRectangle(cornerRadius: 2)
                    .fill(placeholderColor)
                    .frame(width: 120, height: 24)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(maxWidth: .infinity)

            Spacer()

            // Right section
            VStack(spacing: VivaDesign.Spacing.small) {
                // "All-Time Wins" label placeholder
                RoundedRectangle(cornerRadius: 2)
                    .fill(placeholderColor)
                    .frame(width: 80, height: 10)
                    .frame(maxWidth: .infinity, alignment: .center)

                // Record display placeholder
                HStack(spacing: VivaDesign.Spacing.medium) {
                    Circle()
                        .fill(placeholderColor)
                        .frame(
                            width: VivaDesign.Sizing.ProfileImage.mini.rawValue,
                            height: VivaDesign.Sizing.ProfileImage.mini.rawValue
                        )

                    RoundedRectangle(cornerRadius: 2)
                        .fill(placeholderColor)
                        .frame(width: 20, height: 30)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(placeholderColor)
                        .frame(width: 20, height: 30)

                    Circle()
                        .fill(placeholderColor)
                        .frame(
                            width: VivaDesign.Sizing.ProfileImage.mini.rawValue,
                            height: VivaDesign.Sizing.ProfileImage.mini.rawValue
                        )
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - View Components

struct MatchupHeader: View {
    @ObservedObject var viewModel: MatchupDetailViewModel
    @Binding var selectedInvite: MatchupInvite?
    @Binding var showUnInviteSheet: Bool
    @Binding var selectedUserId: String?
    let source: String

    @State private var showInviteView = false
    @State private var inviteMatchupTeamId: String?

    var body: some View {
        HStack(spacing: 0) {
            // Left user with full width to center
            leftUserView
                .frame(maxWidth: .infinity)

            // Right user with full width to center
            rightUserView
                .frame(maxWidth: .infinity)
        }
        .frame(height: 60)
        .sheet(isPresented: $showInviteView) {
            if let matchup = viewModel.matchup {
                MatchupInviteView(
                    matchupService: viewModel.matchupService,
                    friendService: viewModel.friendService,
                    userService: viewModel.userService,
                    userSession: viewModel.userSession,
                    matchup: matchup,
                    usersPerSide: matchup.usersPerSide,
                    showCreationFlow: $showInviteView,
                    isInvitingFromDetails: true,
                    preferredTeamId: inviteMatchupTeamId,
                    source: source
                )
            }
        }
    }

    private var leftUserView: some View {
        let leftTeamId = viewModel.matchup?.leftTeam.id
        let leftUser = viewModel.matchup?.leftTeam.users.first
        let leftInvite = viewModel.matchup?.invites.first(where: {
            $0.matchupTeamId == leftTeamId
        })
        let isCompleted = viewModel.matchup?.status == .completed
        let leftPoints = viewModel.matchup?.leftTeam.points ?? 0
        let rightPoints = viewModel.matchup?.rightTeam.points ?? 0
        let isLeftWinner = isCompleted && leftPoints > rightPoints

        return UserScoreView(
            matchupUser: leftUser,
            invite: leftInvite,
            totalPoints: leftPoints,
            imageOnLeft: true,
            onInviteTap: { invite in
                selectedInvite = invite
                withAnimation(.easeInOut(duration: 0.2)) {
                    showUnInviteSheet = true
                }
            },
            onOpenPositionTap: {
                inviteMatchupTeamId = leftTeamId
                showInviteView = true
            },
            onUserProfileTap: { userId in
                selectedUserId = userId
            },
            isCompleted: isCompleted,
            isWinner: isLeftWinner
        )
    }

    private var rightUserView: some View {
        let rightTeamId = viewModel.matchup?.rightTeam.id
        let rightUser = viewModel.matchup?.rightTeam.users.first
        let rightInvite = viewModel.matchup?.invites.first(where: {
            $0.matchupTeamId == rightTeamId
        })
        let isCompleted = viewModel.matchup?.status == .completed
        let leftPoints = viewModel.matchup?.leftTeam.points ?? 0
        let rightPoints = viewModel.matchup?.rightTeam.points ?? 0
        let isRightWinner = isCompleted && rightPoints > leftPoints

        return UserScoreView(
            matchupUser: rightUser,
            invite: rightInvite,
            totalPoints: rightPoints,
            imageOnLeft: false,
            onInviteTap: { invite in
                selectedInvite = invite
                withAnimation(.easeInOut(duration: 0.2)) {
                    showUnInviteSheet = true
                }
            },
            onOpenPositionTap: {
                inviteMatchupTeamId = rightTeamId
                showInviteView = true
            },
            onUserProfileTap: { userId in
                selectedUserId = userId
            },
            isCompleted: isCompleted,
            isWinner: isRightWinner
        )
    }
}

struct UserScoreView: View {
    let matchupUser: UserSummary?
    let invite: MatchupInvite?
    let totalPoints: Int
    let imageOnLeft: Bool
    let onInviteTap: ((MatchupInvite) -> Void)?
    let onOpenPositionTap: (() -> Void)?
    let onUserProfileTap: ((String) -> Void)?
    let isCompleted: Bool
    let isWinner: Bool

    init(
        matchupUser: UserSummary?,
        invite: MatchupInvite?,
        totalPoints: Int,
        imageOnLeft: Bool,
        onInviteTap: ((MatchupInvite) -> Void)?,
        onOpenPositionTap: (() -> Void)?,
        onUserProfileTap: ((String) -> Void)? = nil,
        isCompleted: Bool = false,
        isWinner: Bool = false
    ) {
        self.matchupUser = matchupUser
        self.invite = invite
        self.totalPoints = totalPoints
        self.imageOnLeft = imageOnLeft
        self.onInviteTap = onInviteTap
        self.onOpenPositionTap = onOpenPositionTap
        self.onUserProfileTap = onUserProfileTap
        self.isCompleted = isCompleted
        self.isWinner = isWinner
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            if imageOnLeft {
                userImage
                userInfo
                    .frame(maxWidth: .infinity)
            } else {
                userInfo
                    .frame(maxWidth: .infinity)
                userImage
            }
        }
        .frame(height: 60)
    }

    private var userImage: some View {
        Group {
            if invite != nil || matchupUser != nil {
                let userId = invite?.user?.id ?? matchupUser?.id
                VivaProfileImage(
                    userId: userId,
                    imageUrl: invite?.user?.imageUrl ?? matchupUser?.imageUrl,
                    size: .large,
                    isInvited: invite?.user != nil
                )
                .onTapGesture {
                    if let invite = invite {
                        onInviteTap?(invite)
                    } else if let id = userId {
                        onUserProfileTap?(id)
                    }
                }
            } else {
                // Open position with invite button
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 44))
                    .foregroundColor(VivaDesign.Colors.secondaryText)
                    .onTapGesture {
                        onOpenPositionTap?()
                    }
            }
        }
    }

    private var userInfo: some View {
        VStack(alignment: .center) {
            Text(displayName)
                .foregroundColor(VivaDesign.Colors.primaryText)
                .font(VivaDesign.Typography.caption.bold())
                .vivaText()
            Text("\(totalPoints)")
                .foregroundColor(VivaDesign.Colors.primaryText)
                .font(VivaDesign.Typography.points)
                .vivaText()
        }
        .lineLimit(1)
        .truncationMode(.tail)
    }

    private var displayName: String {
        if let invitedUser = invite?.user {
            return "\(invitedUser.displayName)"
        } else if let user = matchupUser {
            return user.displayName
        } else {
            return "Open Position"
        }
    }
}

struct ViewToggle: View {
    @Binding var isShowingTotal: Bool
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: VivaDesign.Spacing.medium) {
            // Left line
            VivaDivider()

            // Toggle text with vertical separator
            HStack(spacing: VivaDesign.Spacing.xsmall) {
                Text("Today")
                    .font(VivaDesign.Typography.pointsTitle)
                    .fontWeight(.bold)
                    .foregroundColor(
                        isShowingTotal
                            ? VivaDesign.Colors.secondaryText
                            : VivaDesign.Colors.vivaGreen
                    )
                    .vivaText()

                Text("|")
                    .foregroundColor(VivaDesign.Colors.vivaGreen)
                    .vivaText()

                Text("Total")
                    .font(VivaDesign.Typography.pointsTitle)
                    .fontWeight(.bold)
                    .foregroundColor(
                        isShowingTotal
                            ? VivaDesign.Colors.vivaGreen
                            : VivaDesign.Colors.secondaryText
                    )
                    .vivaText()
            }

            // Right line
            VivaDivider()
        }
        .onTapGesture {
            withAnimation {
                isShowingTotal.toggle()
            }
        }
    }
}

struct ComparisonRow: View {
    let id: String
    let leftValue: String
    let leftPoints: String
    let title: String
    let rightValue: String
    let rightPoints: String

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                    .frame(width: VivaDesign.Spacing.medium)

                leftSide

                Spacer()

                // Center text with fixed position
                centerTitle

                Spacer()

                rightSide

                Spacer()
                    .frame(width: VivaDesign.Spacing.medium)
            }
            .padding(.vertical, VivaDesign.Spacing.componentSmall)

            VivaDivider()
        }
    }

    private var leftSide: some View {
        // Left side with fixed width
        VStack(alignment: .center) {
            Text(leftValue)
                .font(Font.system(size: 20, weight: .bold))
                .fontWeight(.bold)
                .foregroundColor(VivaDesign.Colors.primaryText)
                .vivaText()
            Text(leftPoints)
                .font(Font.system(size: 12, weight: .bold))
                .fontWeight(.bold)
                .foregroundColor(VivaDesign.Colors.vivaGreen)
                .vivaText()
        }
        .frame(width: 80, alignment: .center)  // Fixed width with center alignment
    }

    private var centerTitle: some View {
        Text(title)
            .font(VivaDesign.Typography.pointsTitle)
            .foregroundColor(VivaDesign.Colors.primaryText)
            .vivaText()
            .frame(width: 140, alignment: .center)  // Fixed width
    }

    private var rightSide: some View {
        // Right side with fixed width
        VStack(alignment: .center) {
            Text(rightValue)
                .font(Font.system(size: 20, weight: .bold))
                .fontWeight(.bold)
                .foregroundColor(VivaDesign.Colors.primaryText)
                .vivaText()
            Text(rightPoints)
                .font(Font.system(size: 12, weight: .bold))
                .fontWeight(.bold)
                .foregroundColor(VivaDesign.Colors.vivaGreen)
                .vivaText()
        }
        .frame(width: 80, alignment: .center)  // Fixed width with center alignment
    }
}

struct WorkoutListSection: View {
    let userId: String
    @ObservedObject var viewModel: MatchupDetailViewModel
    
    var body: some View {
        Section {
            // Workout list
            if let workouts = viewModel.matchup?.workouts, !workouts.isEmpty {
                ForEach(workouts) { workout in
                    WorkoutCard(workout: workout)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                        .padding(.vertical, VivaDesign.Spacing.xsmall)
                    
                    VivaDivider()
                }
            } else {
                Text("No workouts recorded")
                    .foregroundColor(VivaDesign.Colors.secondaryText)
                    .font(VivaDesign.Typography.body)
                    .vivaText()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, VivaDesign.Spacing.medium)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
            }
        } header: {
            SectionHeaderView(title: "Workouts")
        }
    }
}

struct MatchupFooter: View {
    let endTime: Date?
    let leftUser: UserSummary?
    let rightUser: UserSummary?
    let record: (leftWins: Int, rightWins: Int)
    let isCompleted: Bool
    let matchupService: MatchupService
    let friendService: FriendService
    let userService: UserService
    let userSession: UserSession
    @State private var showRematchCategories = false
    let matchupId: String?
    @Binding var selectedUserId: String?
    let source: String

    var body: some View {
        if isCompleted {
            // Completed matchup layout
            VStack(spacing: 0) {
                // All-Time Wins with record
                VStack(spacing: VivaDesign.Spacing.small) {
                    // All-Time Wins label
                    Text("All-Time Wins")
                        .font(VivaDesign.Typography.caption.bold())
                        .foregroundColor(VivaDesign.Colors.primaryText)
                        .vivaText()

                    // Record display
                    RecordDisplay(
                        leftUser: leftUser,
                        rightUser: rightUser,
                        record: record,
                        selectedUserId: $selectedUserId
                    )
                }.padding(.bottom, VivaDesign.Spacing.small)

                // Rematch button
                Button {
                    showRematchCategories = true
                } label: {
                    Text("Rematch")
                        .font(.system(size: 24, weight: .semibold))
                        .vivaText()
                        .padding(.horizontal, 60)
                        .padding(.vertical, VivaDesign.Spacing.small)
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white, lineWidth: 1)
                        )
                }
                .padding(.horizontal, VivaDesign.Spacing.large)
                .padding(.bottom, VivaDesign.Spacing.medium)
                .sheet(isPresented: $showRematchCategories) {
                    if let matchupId = matchupId {
                        MatchupCategoriesView(
                            matchupService: matchupService,
                            friendService: friendService,
                            userService: userService,
                            userSession: userSession,
                            showCreationFlow: $showRematchCategories,
                            source: source,
                            rematchMatchupId: matchupId
                        )
                        .presentationBackground(.clear)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        } else {
            // Active matchup layout

            HStack {
                // Left section
                VStack(spacing: VivaDesign.Spacing.small) {
                    Text("Matchup Ends")
                        .font(VivaDesign.Typography.caption.bold())
                        .foregroundColor(VivaDesign.Colors.primaryText)
                        .vivaText()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .opacity(endTime != nil && endTime! > Date() ? 1 : 0)  // Hide when waiting for data
                    TimeRemainingDisplay(
                        endTime: endTime,
                        isCompleted: isCompleted
                    )
                }
                .frame(maxWidth: .infinity)

                Spacer()

                // Right section
                VStack(spacing: VivaDesign.Spacing.small) {
                    Text("All-Time Wins")
                        .font(VivaDesign.Typography.caption.bold())
                        .foregroundColor(VivaDesign.Colors.primaryText)
                        .vivaText()
                        .frame(maxWidth: .infinity, alignment: .center)
                    RecordDisplay(
                        leftUser: leftUser,
                        rightUser: rightUser,
                        record: record,
                        selectedUserId: $selectedUserId
                    )
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct TimeRemainingDisplay: View {
    let endTime: Date?
    let isCompleted: Bool

    var body: some View {
        if isCompleted {
            completedView
        } else if endTime == nil {
            notStartedView
        } else if endTime! <= Date() {
            waitingView
        } else {
            countdownView
        }
    }

    private var completedView: some View {
        HStack(spacing: VivaDesign.Spacing.xsmall) {
            Text("Complete")
                .font(.title)
                .foregroundColor(VivaDesign.Colors.vivaGreen)
                .vivaText()
        }
    }

    private var notStartedView: some View {
        HStack(spacing: VivaDesign.Spacing.xsmall) {
            Text("Not started")
                .font(.title)
                .vivaText()
        }
        .foregroundColor(VivaDesign.Colors.primaryText)
    }

    private var waitingView: some View {
        Text("Waiting for final data")
            .font(.title3.bold())
            .foregroundColor(VivaDesign.Colors.primaryText)
            .padding(.horizontal, VivaDesign.Spacing.small)
            .vivaText()
    }

    private var countdownView: some View {
        let remainingTime = calculateTimeRemaining()

        return HStack(spacing: VivaDesign.Spacing.xsmall) {
            Text("\(remainingTime.days)")
                .font(.title.bold())
                .vivaText()
            Text("d")
                .foregroundColor(VivaDesign.Colors.vivaGreen)
                .font(VivaDesign.Typography.caption.bold())
                .vivaText()
            Text("\(remainingTime.hours)")
                .font(.title.bold())
                .vivaText()
            Text("hr")
                .foregroundColor(VivaDesign.Colors.vivaGreen)
                .font(VivaDesign.Typography.caption.bold())
                .vivaText()
            Text("\(remainingTime.minutes)")
                .font(.title.bold())
                .vivaText()
            Text("min")
                .foregroundColor(VivaDesign.Colors.vivaGreen)
                .font(VivaDesign.Typography.caption.bold())
                .vivaText()
        }
        .fixedSize(horizontal: true, vertical: false)
        .foregroundColor(VivaDesign.Colors.primaryText)
    }

    private func calculateTimeRemaining() -> (
        days: Int, hours: Int, minutes: Int
    ) {
        let currentTime = Date()
        let timeInterval = max(endTime!.timeIntervalSince(currentTime), 0)

        let days = Int(timeInterval) / (24 * 60 * 60)
        let hours = (Int(timeInterval) % (24 * 60 * 60)) / (60 * 60)
        let minutes = (Int(timeInterval) % (60 * 60)) / 60

        return (days, hours, minutes)
    }
}

struct RecordDisplay: View {
    let leftUser: UserSummary?
    let rightUser: UserSummary?
    let record: (leftWins: Int, rightWins: Int)
    @Binding var selectedUserId: String?

    var body: some View {
        HStack(spacing: 0) {
            VivaProfileImage(
                userId: leftUser?.id,
                imageUrl: leftUser?.imageUrl,
                size: .mini
            )
            .onTapGesture {
                if let id = leftUser?.id {
                    selectedUserId = id
                }
            }
            
            Text("\(record.leftWins)")
                .font(.system(size: 30, weight: .bold))
                .padding(.horizontal, VivaDesign.Spacing.xsmall)
                .vivaText()
                .minimumScaleFactor(0.8)

            Text("\(record.rightWins)")
                .font(.system(size: 30, weight: .bold))
                .padding(.horizontal, VivaDesign.Spacing.xsmall)
                .vivaText()
                .minimumScaleFactor(0.8)

            VivaProfileImage(
                userId: rightUser?.id,
                imageUrl: rightUser?.imageUrl,
                size: .mini
            )
            .onTapGesture {
                if let id = rightUser?.id {
                    selectedUserId = id
                }
            }
        }
        .foregroundColor(VivaDesign.Colors.primaryText)
    }
}

struct InviteDialog: View {
    @ObservedObject var viewModel: MatchupDetailViewModel
    @Binding var showUnInviteSheet: Bool
    @Binding var selectedInvite: MatchupInvite?
    @Binding var selectedUserId: String?

    let user: UserSummary
    let inviteCode: String

    var body: some View {
        VStack(spacing: VivaDesign.Spacing.medium) {
            // User info
            HStack(spacing: VivaDesign.Spacing.medium) {
                VivaProfileImage(
                    userId: user.id,
                    imageUrl: user.imageUrl,
                    size: .medium,
                    isInvited: true
                )
                .onTapGesture {
                    selectedUserId = user.id
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showUnInviteSheet = false
                    }
                }
                
                Text(user.displayName)
                    .font(VivaDesign.Typography.title2)
                    .foregroundColor(VivaDesign.Colors.primaryText)
                    .vivaText()
            }
            .padding(.top, VivaDesign.Spacing.medium)

            // Actions
            VStack(spacing: VivaDesign.Spacing.small) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showUnInviteSheet = false
                        selectedInvite = nil
                    }
                    Task {
                        await viewModel.deleteInvite(inviteCode: inviteCode)
                    }
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Cancel Invitation")
                            .vivaText()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(VivaDesign.Colors.destructive)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showUnInviteSheet = false
                        selectedInvite = nil
                    }
                } label: {
                    Text("Dismiss")
                        .vivaText()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(
                            VivaDesign.Colors.primaryText
                        )
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .frame(width: 300)
        .background(VivaDesign.Colors.background)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
        )
        .shadow(radius: 20)
        .transition(.opacity.combined(with: .scale))
    }
}

struct MatchupResultMessage: View {
    let userIsWinner: Bool
    let opponentName: String

    var body: some View {
        HStack {
            Spacer()
            if userIsWinner {
                Text("You won this one! Nice work staying active.")
                    .foregroundColor(VivaDesign.Colors.primaryText)
                    .font(VivaDesign.Typography.body)
                    .vivaText()
            } else {
                Text("\(opponentName) took this one. Nice work staying active!")
                    .foregroundColor(VivaDesign.Colors.primaryText)
                    .font(VivaDesign.Typography.body)
                    .vivaText()
            }
            Spacer()
        }
    }
}

struct MatchupDetailContent: View {
    @ObservedObject var viewModel: MatchupDetailViewModel
    @Binding var isShowingTotal: Bool
    @Binding var selectedInvite: MatchupInvite?
    @Binding var showUnInviteSheet: Bool
    @Binding var selectedUserId: String?
    let source: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        if viewModel.isLoading && viewModel.matchup == nil {
            MatchupDetailSkeletonView()
        } else if let matchup = viewModel.matchup {
            MatchupDetailLoadedView(
                viewModel: viewModel,
                matchup: matchup,
                isShowingTotal: $isShowingTotal,
                selectedInvite: $selectedInvite,
                showUnInviteSheet: $showUnInviteSheet,
                selectedUserId: $selectedUserId,
                source: source
            )
        } else {
            MatchupDetailErrorView(viewModel: viewModel)
        }
    }
}

struct MatchupDetailSkeletonView: View {
    // Add skeleton opacity constant
    private let skeletonOpacity: Double = 1.0
    
    var body: some View {
        VStack(spacing: 0) {
            // Scrollable skeleton content
            List {
                VStack(spacing: VivaDesign.Spacing.medium) {
                    // Header skeleton
                    skeletonHeader
                        .padding(.horizontal, VivaDesign.Spacing.screenPadding)
                        .padding(.top, VivaDesign.Spacing.medium)

                    // Toggle skeleton
                    skeletonToggle

                    // Comparison rows skeleton
                    VStack(spacing: VivaDesign.Spacing.medium) {
                        ForEach(0..<5, id: \.self) { _ in
                            skeletonComparisonRow
                        }
                    }
                    .padding(.horizontal, VivaDesign.Spacing.screenPadding)
                }
                .listRowBackground(VivaDesign.Colors.surface)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
                
                // Add empty space at the bottom for footer
                Color.clear
                    .frame(height: 100)
                    .listRowBackground(VivaDesign.Colors.surface)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
            }
            .listStyle(PlainListStyle())
            .scrollContentBackground(.hidden)

            // Footer skeleton
            skeletonFooter
                .padding(.horizontal, VivaDesign.Spacing.screenPadding)
                .padding(.vertical, VivaDesign.Spacing.medium)
                .background(VivaDesign.Colors.surface)
        }
        .shimmering(animation: VivaDesign.Animation.loadingShimmer)
    }
    
    private var skeletonHeader: some View {
        let placeholderColor = Color.gray.opacity(skeletonOpacity)

        return HStack(spacing: 0) {
            // Left user
            HStack(alignment: .center, spacing: 0) {
                // Profile image placeholder
                Circle()
                    .fill(placeholderColor)
                    .frame(
                        width: VivaDesign.Sizing.ProfileImage.large.rawValue,
                        height: VivaDesign.Sizing.ProfileImage.large.rawValue
                    )

                // Username and points placeholders
                VStack(alignment: .center) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(placeholderColor)
                        .frame(width: 60, height: 10)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(placeholderColor)
                        .frame(width: 40, height: 18)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)

            // Right user
            HStack(alignment: .center, spacing: 0) {
                // Username and points placeholders
                VStack(alignment: .center) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(placeholderColor)
                        .frame(width: 60, height: 10)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(placeholderColor)
                        .frame(width: 40, height: 18)
                }
                .frame(maxWidth: .infinity)

                // Profile image placeholder
                Circle()
                    .fill(placeholderColor)
                    .frame(
                        width: VivaDesign.Sizing.ProfileImage.large.rawValue,
                        height: VivaDesign.Sizing.ProfileImage.large.rawValue
                    )
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 60)
    }

    private var skeletonToggle: some View {
        let placeholderColor = Color.gray.opacity(skeletonOpacity)

        return HStack(spacing: VivaDesign.Spacing.medium) {
            // Left line
            Rectangle()
                .fill(placeholderColor)
                .frame(height: 1)
                .padding(.leading, VivaDesign.Spacing.small)

            // Toggle placeholder
            RoundedRectangle(cornerRadius: 2)
                .fill(placeholderColor)
                .frame(width: 120, height: 20)

            // Right line
            Rectangle()
                .fill(placeholderColor)
                .frame(height: 1)
                .padding(.trailing, VivaDesign.Spacing.small)
        }
    }

    private var skeletonComparisonRow: some View {
        let placeholderColor = Color.gray.opacity(skeletonOpacity)

        return VStack {
            HStack {
                Spacer()
                    .frame(width: VivaDesign.Spacing.medium)

                // Left side placeholders
                VStack(alignment: .center) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(placeholderColor)
                        .frame(width: 40, height: 24)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(placeholderColor)
                        .frame(width: 60, height: 12)
                }
                .frame(width: 80, alignment: .center)

                Spacer()

                // Center title placeholder
                RoundedRectangle(cornerRadius: 2)
                    .fill(placeholderColor)
                    .frame(width: 100, height: 14)
                    .frame(width: 140, alignment: .center)

                Spacer()

                // Right side placeholders
                VStack(alignment: .center) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(placeholderColor)
                        .frame(width: 40, height: 24)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(placeholderColor)
                        .frame(width: 60, height: 12)
                }
                .frame(width: 80, alignment: .center)

                Spacer()
                    .frame(width: VivaDesign.Spacing.medium)
            }

            // Divider placeholder
            VivaDivider()
                .padding(.top, VivaDesign.Spacing.small)
        }
    }

    private var skeletonFooter: some View {
        let placeholderColor = Color.gray.opacity(skeletonOpacity)

        return HStack {
            // Left section
            VStack(spacing: VivaDesign.Spacing.small) {
                // "Matchup Ends" label placeholder
                RoundedRectangle(cornerRadius: 2)
                    .fill(placeholderColor)
                    .frame(width: 80, height: 10)
                    .frame(maxWidth: .infinity, alignment: .center)

                // Time remaining placeholder
                RoundedRectangle(cornerRadius: 2)
                    .fill(placeholderColor)
                    .frame(width: 120, height: 24)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(maxWidth: .infinity)

            Spacer()

            // Right section
            VStack(spacing: VivaDesign.Spacing.small) {
                // "All-Time Wins" label placeholder
                RoundedRectangle(cornerRadius: 2)
                    .fill(placeholderColor)
                    .frame(width: 80, height: 10)
                    .frame(maxWidth: .infinity, alignment: .center)

                // Record display placeholder
                HStack(spacing: VivaDesign.Spacing.medium) {
                    Circle()
                        .fill(placeholderColor)
                        .frame(
                            width: VivaDesign.Sizing.ProfileImage.mini.rawValue,
                            height: VivaDesign.Sizing.ProfileImage.mini.rawValue
                        )

                    RoundedRectangle(cornerRadius: 2)
                        .fill(placeholderColor)
                        .frame(width: 20, height: 30)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(placeholderColor)
                        .frame(width: 20, height: 30)

                    Circle()
                        .fill(placeholderColor)
                        .frame(
                            width: VivaDesign.Sizing.ProfileImage.mini.rawValue,
                            height: VivaDesign.Sizing.ProfileImage.mini.rawValue
                        )
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct MatchupDetailErrorView: View {
    @ObservedObject var viewModel: MatchupDetailViewModel
    
    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(VivaDesign.Colors.secondaryText)
                .padding(.bottom, VivaDesign.Spacing.medium)

            Text("Failed to load matchup")
                .font(VivaDesign.Typography.title3)
                .foregroundColor(VivaDesign.Colors.primaryText)
                .vivaText()

            Button("Try Again") {
                Task {
                    await viewModel.loadData()
                }
            }
            .padding(.top, VivaDesign.Spacing.medium)
            .foregroundColor(VivaDesign.Colors.vivaGreen)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MatchupDetailLoadedView: View {
    @ObservedObject var viewModel: MatchupDetailViewModel
    let matchup: MatchupDetails
    @Binding var isShowingTotal: Bool
    @Binding var selectedInvite: MatchupInvite?
    @Binding var showUnInviteSheet: Bool
    @Binding var selectedUserId: String?
    let source: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Scrollable content
            List {
                // Show MATCHUP RECAP title if completed
                if matchup.status == .completed {
                    Text("MATCHUP RECAP")
                        .font(.title)
                        .fontWeight(.bold)
                        .vivaText()
                        .foregroundColor(
                            VivaDesign.Colors.primaryText
                        )
                        .frame(
                            maxWidth: .infinity,
                            alignment: .center
                        )
                        .padding(.top, VivaDesign.Spacing.small)
                        .padding(.bottom, VivaDesign.Spacing.medium)
                        .listRowBackground(VivaDesign.Colors.surface)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                }

                // Matchup Header
                MatchupHeader(
                    viewModel: viewModel,
                    selectedInvite: $selectedInvite,
                    showUnInviteSheet: $showUnInviteSheet,
                    selectedUserId: $selectedUserId,
                    source: source
                )
                .padding(.top, matchup.status == .completed ? 0 : VivaDesign.Spacing.medium)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())

                // Show matchup result message - if completed
                if matchup.status == .completed {
                    // Winning and losing teams
                    let currentUserId = viewModel.userSession.userId
                    let userTeam =
                        matchup.leftTeam.users
                            .contains(where: {
                                $0.id == currentUserId
                            })
                        ? matchup.leftTeam : matchup.rightTeam
                    let opponentTeam =
                        userTeam == matchup.leftTeam
                        ? matchup.rightTeam : matchup.leftTeam
                    let userIsWinner =
                        userTeam.points > opponentTeam.points
                    let oppopnentName =
                        opponentTeam.users.first?
                        .displayName ?? "Opponent"

                    MatchupResultMessage(
                        userIsWinner: userIsWinner,
                        opponentName: oppopnentName
                    )
                    .padding(.vertical, VivaDesign.Spacing.large)
                    .listRowBackground(VivaDesign.Colors.surface)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
                }

                // Toggle - only show for active matchups
                if matchup.status != .completed {
                    ViewToggle(
                        isShowingTotal: $isShowingTotal,
                        isCompleted: false
                    )
                    .padding(.vertical, VivaDesign.Spacing.medium)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
                }

                // Comparison rows
                ForEach(
                    isShowingTotal
                        ? viewModel.totalComparisonRows
                        : viewModel.dailyComparisonRows
                ) { row in
                    ComparisonRow(
                        id: row.id,
                        leftValue: row.formattedLeftValue,
                        leftPoints: "\(row.leftPoints) pts",
                        title: row.displayName,
                        rightValue: row.formattedRightValue,
                        rightPoints: "\(row.rightPoints) pts"
                    )
                    .listRowBackground(VivaDesign.Colors.surface)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
                }
                
                // Add workouts section
                if let userId = viewModel.userSession.userId {
                    WorkoutListSection(userId: userId, viewModel: viewModel)
                        .listRowBackground(VivaDesign.Colors.surface)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                }
                
                // Add empty space at the bottom for footer
                Color.clear
                    .frame(height: 100)
                    .listRowBackground(VivaDesign.Colors.surface)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
            }
            .listStyle(PlainListStyle())
            .environment(\.defaultMinListRowHeight, 0)
            .scrollContentBackground(.hidden)
            .refreshable {
                await viewModel.loadData()
            }
            .gesture(
                DragGesture()
                    .onEnded { gesture in
                        if gesture.translation.width > 100 {
                            dismiss()
                        }
                    }
            )
            
            // Footer pinned to bottom
            MatchupFooter(
                endTime: matchup.endTime,
                leftUser: matchup.leftTeam.users.first,
                rightUser: matchup.rightTeam.users.first,
                record: (
                    leftWins: matchup.leftTeam.winCount,
                    rightWins: matchup.rightTeam.winCount
                ),
                isCompleted: matchup.status == .completed,
                matchupService: viewModel.matchupService,
                friendService: viewModel.friendService,
                userService: viewModel.userService,
                userSession: viewModel.userSession,
                matchupId: matchup.id,
                selectedUserId: $selectedUserId,
                source: source
            )
            .padding(.vertical, VivaDesign.Spacing.componentSmall)
            .padding(.horizontal, VivaDesign.Spacing.screenPadding)
            .background(VivaDesign.Colors.surface)
        }
        .padding(.horizontal, VivaDesign.Spacing.screenPadding)
    }
}
