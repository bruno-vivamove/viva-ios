import Charts
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
    @StateObject private var viewModel: MatchupDetailViewModel
    @State private var isShowingTotal = true
    @State private var showUnInviteSheet = false
    @State private var selectedInvite: MatchupInvite? = nil
    @Environment(\.dismiss) private var dismiss

    init(
        viewModel: MatchupDetailViewModel
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            // Background color
            Color.black.edgesIgnoringSafeArea(.all)

            // Main content
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let matchup = viewModel.matchup {
                VStack(spacing: 0) {
                    // Scrollable content
                    List {
                        VStack(spacing: VivaDesign.Spacing.medium) {
                            // Show MATCHUP RECAP title if completed
                            if matchup.status == .completed {
                                Text("MATCHUP RECAP")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(
                                        VivaDesign.Colors.primaryText
                                    )
                                    .frame(
                                        maxWidth: .infinity, alignment: .center
                                    )
                                    .padding(.top, VivaDesign.Spacing.small)
                            }

                            // Matchup Header
                            MatchupHeader(
                                viewModel: viewModel,
                                selectedInvite: $selectedInvite,
                                showUnInviteSheet: $showUnInviteSheet
                            )
                            .padding(
                                .horizontal, VivaDesign.Spacing.outerPadding)

                            // Show reward indicator if completed
                            if matchup.status == .completed {
                                Spacer()
                                    .frame(height: VivaDesign.Spacing.small)

                                // Determine if current user is on winning side
                                let currentUserId = viewModel.userSession.userId
                                let isUserOnLeftSide = matchup.leftUsers
                                    .contains(where: { $0.id == currentUserId })
                                let leftWon =
                                    matchup.leftSidePoints
                                    > matchup.rightSidePoints
                                let userWon =
                                    (isUserOnLeftSide && leftWon)
                                    || (!isUserOnLeftSide && !leftWon)

                                RewardIndicator(
                                    userWon: userWon,
                                    opponentName: userWon
                                        ? (isUserOnLeftSide
                                            ? matchup.rightUsers.first?
                                                .displayName ?? "Opponent"
                                            : matchup.leftUsers.first?
                                                .displayName ?? "Opponent")
                                        : (isUserOnLeftSide
                                            ? matchup.leftUsers.first?
                                                .displayName ?? "You"
                                            : matchup.rightUsers.first?
                                                .displayName ?? "You"),
                                    rewardCoins: 125
                                )
                                .padding(
                                    .horizontal, VivaDesign.Spacing.outerPadding
                                )

                                Spacer()
                                    .frame(height: VivaDesign.Spacing.small)
                            }

                            // Toggle - only show for active matchups
                            if matchup.status != .completed {
                                ViewToggle(
                                    isShowingTotal: $isShowingTotal,
                                    isCompleted: false)
                            }

                            // Comparison rows
                            VStack(spacing: VivaDesign.Spacing.medium) {
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
                                }
                            }
                            .padding(
                                .horizontal, VivaDesign.Spacing.outerPadding)
                        }
                        .padding(.top, VivaDesign.Spacing.medium)
                        .listRowBackground(Color.black)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                    }
                    .listStyle(PlainListStyle())
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

                    // Fixed footer
                    MatchupFooter(
                        endTime: matchup.endTime,
                        leftUser: matchup.leftUsers.first,
                        rightUser: matchup.rightUsers.first,
                        record: (wins: 0, losses: 0),
                        isCompleted: matchup.status == .completed
                    )
                    .padding(.horizontal, VivaDesign.Spacing.outerPadding)
                    .padding(.vertical, VivaDesign.Spacing.medium)
                    .background(.black)
                }
            }

            // Overlay
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

                InviteDialog(
                    viewModel: viewModel,
                    showUnInviteSheet: $showUnInviteSheet,
                    selectedInvite: $selectedInvite,
                    user: user,
                    inviteCode: invite.inviteCode
                )
            }
        }
        .task {
            await viewModel.loadData()
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }
}

// MARK: - View Components

struct MatchupHeader: View {
    @ObservedObject var viewModel: MatchupDetailViewModel
    @Binding var selectedInvite: MatchupInvite?
    @Binding var showUnInviteSheet: Bool

    @State private var showInviteView = false
    @State private var inviteSide: MatchupUser.Side?

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
                    preferredSide: inviteSide
                )
            }
        }
    }

    private var leftUserView: some View {
        let leftUser = viewModel.matchup?.leftUsers.first
        let leftInvite = viewModel.matchup?.invites.first(where: {
            $0.side == .left
        })
        let isCompleted = viewModel.matchup?.status == .completed
        let leftPoints = viewModel.matchup?.leftSidePoints ?? 0
        let rightPoints = viewModel.matchup?.rightSidePoints ?? 0
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
                inviteSide = .left
                showInviteView = true
            },
            isCompleted: isCompleted,
            isWinner: isLeftWinner
        )
    }

    private var rightUserView: some View {
        let rightUser = viewModel.matchup?.rightUsers.first
        let rightInvite = viewModel.matchup?.invites.first(where: {
            $0.side == .right
        })
        let isCompleted = viewModel.matchup?.status == .completed
        let leftPoints = viewModel.matchup?.leftSidePoints ?? 0
        let rightPoints = viewModel.matchup?.rightSidePoints ?? 0
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
                inviteSide = .right
                showInviteView = true
            },
            isCompleted: isCompleted,
            isWinner: isRightWinner
        )
    }
}

struct UserScoreView: View {
    let matchupUser: User?
    let invite: MatchupInvite?
    let totalPoints: Int
    let imageOnLeft: Bool
    let onInviteTap: ((MatchupInvite) -> Void)?
    let onOpenPositionTap: (() -> Void)?
    let isCompleted: Bool
    let isWinner: Bool

    init(
        matchupUser: User?,
        invite: MatchupInvite?,
        totalPoints: Int,
        imageOnLeft: Bool,
        onInviteTap: ((MatchupInvite) -> Void)?,
        onOpenPositionTap: (() -> Void)?,
        isCompleted: Bool = false,
        isWinner: Bool = false
    ) {
        self.matchupUser = matchupUser
        self.invite = invite
        self.totalPoints = totalPoints
        self.imageOnLeft = imageOnLeft
        self.onInviteTap = onInviteTap
        self.onOpenPositionTap = onOpenPositionTap
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
                VivaProfileImage(
                    userId: invite?.user?.id ?? matchupUser?.id,
                    imageUrl: invite?.user?.imageUrl ?? matchupUser?.imageUrl,
                    size: .large,
                    isInvited: invite?.user != nil
                )
                .onTapGesture {
                    if let invite = invite {
                        onInviteTap?(invite)
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
                .foregroundColor(VivaDesign.Colors.vivaGreen)
                .font(VivaDesign.Typography.caption)
                .lineLimit(1)
            Text("\(totalPoints)")
                .foregroundColor(VivaDesign.Colors.primaryText)
                .font(VivaDesign.Typography.points)
                .lineLimit(1)
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
                .padding(.leading, VivaDesign.Spacing.small)

            // Toggle text with vertical separator
            HStack(spacing: VivaDesign.Spacing.xsmall) {
                Text("Today")
                    .lineLimit(1)
                    .fontWeight(.bold)
                    .truncationMode(.tail)
                    .foregroundColor(
                        isShowingTotal
                            ? VivaDesign.Colors.secondaryText
                            : VivaDesign.Colors.vivaGreen)

                Text("|")
                    .foregroundColor(VivaDesign.Colors.vivaGreen)

                Text("Total")
                    .lineLimit(1)
                    .fontWeight(.bold)
                    .truncationMode(.tail)
                    .foregroundColor(
                        isShowingTotal
                            ? VivaDesign.Colors.vivaGreen
                            : VivaDesign.Colors.secondaryText)
            }
            .padding(.vertical, 4)

            // Right line
            VivaDivider()
                .padding(.trailing, VivaDesign.Spacing.small)
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
        VStack {
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

            VivaDivider()
        }
    }

    private var leftSide: some View {
        // Left side with fixed width
        VStack(alignment: .center) {
            Text(leftValue)
                .font(.title2)
                .fontWeight(.bold)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundColor(VivaDesign.Colors.primaryText)
            Text(leftPoints)
                .font(VivaDesign.Typography.caption)
                .fontWeight(.bold)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundColor(VivaDesign.Colors.secondaryText)
        }
        .frame(width: 80, alignment: .center)  // Fixed width with center alignment
    }

    private var centerTitle: some View {
        Text(title)
            .lineLimit(1)
            .truncationMode(.tail)
            .font(VivaDesign.Typography.pointsTitle)
            .foregroundColor(VivaDesign.Colors.vivaGreen)
            .frame(width: 140, alignment: .center)  // Fixed width
    }

    private var rightSide: some View {
        // Right side with fixed width
        VStack(alignment: .center) {
            Text(rightValue)
                .font(.title2)
                .fontWeight(.bold)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundColor(VivaDesign.Colors.primaryText)
            Text(rightPoints)
                .font(VivaDesign.Typography.caption)
                .fontWeight(.bold)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundColor(VivaDesign.Colors.secondaryText)
        }
        .frame(width: 80, alignment: .center)  // Fixed width with center alignment
    }
}

struct WorkoutsSection: View {
    let workouts: [WorkoutEntry]

    var body: some View {
        VStack(spacing: VivaDesign.Spacing.small) {
            Text("Workouts")
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundColor(VivaDesign.Colors.primaryText)
                .frame(maxWidth: .infinity, alignment: .center)

            VivaDivider()

            ForEach(workouts) { workout in
                Text(
                    "\(workout.user) - \(workout.type) - \(workout.calories) Cals"
                )
                .font(VivaDesign.Typography.caption)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundColor(VivaDesign.Colors.primaryText)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}

struct MatchupFooter: View {
    let endTime: Date?
    let leftUser: User?
    let rightUser: User?
    let record: (wins: Int, losses: Int)
    let isCompleted: Bool

    var body: some View {
        if isCompleted {
            // Completed matchup layout
            VStack(spacing: 0) {
                Spacer()  // Push content down

                // All-Time Wins with record
                VStack(spacing: VivaDesign.Spacing.small) {
                    // All-Time Wins label
                    Text("All-Time Wins")
                        .font(VivaDesign.Typography.caption)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundColor(VivaDesign.Colors.primaryText)

                    // Record display
                    RecordDisplay(
                        leftUser: leftUser,
                        rightUser: rightUser,
                        wins: record.wins,
                        losses: record.losses
                    )
                }

                Spacer()  // Space between record and button

                // Rematch button
                Button {
                    // Handle rematch action
                    print("Rematch requested")
                } label: {
                    Text("Rematch")
                        .font(.system(size: 24, weight: .semibold))
                        .padding(.horizontal, 60)
                        .padding(.vertical, VivaDesign.Spacing.medium)
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white, lineWidth: 1)
                        )
                }
                .padding(.horizontal, VivaDesign.Spacing.large)
                .padding(.bottom, VivaDesign.Spacing.medium)
            }
            .frame(maxWidth: .infinity)
        } else {
            // Active matchup layout

            HStack {
                // Left section
                VStack(spacing: VivaDesign.Spacing.small) {
                    Text("Matchup Ends")
                        .font(VivaDesign.Typography.caption)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundColor(VivaDesign.Colors.primaryText)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .opacity(endTime != nil && endTime! > Date() ? 1 : 0)  // Hide when waiting for data
                    TimeRemainingDisplay(
                        endTime: endTime, isCompleted: isCompleted)
                }
                .frame(maxWidth: .infinity)

                Spacer()

                // Right section
                VStack(spacing: VivaDesign.Spacing.small) {
                    Text("All-Time Wins")
                        .font(VivaDesign.Typography.caption)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundColor(VivaDesign.Colors.primaryText)
                        .frame(maxWidth: .infinity, alignment: .center)
                    RecordDisplay(
                        leftUser: leftUser,
                        rightUser: rightUser,
                        wins: record.wins,
                        losses: record.losses
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
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundColor(VivaDesign.Colors.vivaGreen)
        }
    }

    private var notStartedView: some View {
        HStack(spacing: VivaDesign.Spacing.xsmall) {
            Text("Not started")
                .font(.title)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .foregroundColor(VivaDesign.Colors.primaryText)
    }

    private var waitingView: some View {
        Text("Waiting for final data")
            .font(.title3)
            .minimumScaleFactor(0.2)
            .lineLimit(1)
            .foregroundColor(VivaDesign.Colors.vivaGreen)
            .padding(.horizontal, VivaDesign.Spacing.small)
    }

    private var countdownView: some View {
        let remainingTime = calculateTimeRemaining()

        return HStack(spacing: VivaDesign.Spacing.xsmall) {
            Text("\(remainingTime.days)")
                .font(.title)
                .lineLimit(1)
            Text("d")
                .foregroundColor(VivaDesign.Colors.vivaGreen)
                .lineLimit(1)
            Text("\(remainingTime.hours)")
                .font(.title)
                .lineLimit(1)
            Text("hr")
                .foregroundColor(VivaDesign.Colors.vivaGreen)
                .lineLimit(1)
            Text("\(remainingTime.minutes)")
                .font(.title)
                .lineLimit(1)
            Text("min")
                .foregroundColor(VivaDesign.Colors.vivaGreen)
                .lineLimit(1)
        }
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
    let leftUser: User?
    let rightUser: User?
    let wins: Int
    let losses: Int

    var body: some View {
        HStack(spacing: VivaDesign.Spacing.medium) {
            VivaProfileImage(
                userId: leftUser?.id, imageUrl: leftUser?.imageUrl, size: .mini)
            Text("\(wins)")
                .font(.system(size: 30, weight: .bold))
                .lineLimit(1)
            Text("\(losses)")
                .font(.system(size: 30, weight: .bold))
                .lineLimit(1)
            VivaProfileImage(
                userId: rightUser?.id, imageUrl: rightUser?.imageUrl,
                size: .mini)
        }
        .foregroundColor(VivaDesign.Colors.primaryText)
    }
}

struct InviteDialog: View {
    @ObservedObject var viewModel: MatchupDetailViewModel
    @Binding var showUnInviteSheet: Bool
    @Binding var selectedInvite: MatchupInvite?

    let user: User
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

                Text(user.displayName)
                    .font(VivaDesign.Typography.title2)
                    .foregroundColor(VivaDesign.Colors.primaryText)
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

struct RewardIndicator: View {
    let userWon: Bool
    let opponentName: String
    let rewardCoins: Int

    var body: some View {
        HStack {
            Spacer()
            if userWon {
                Text("You won this one and earned ")
                    .foregroundColor(VivaDesign.Colors.primaryText)
                    .font(VivaDesign.Typography.body)
                    + Text("\(rewardCoins) reward coins")
                    .foregroundColor(VivaDesign.Colors.vivaGreen)
                    .font(VivaDesign.Typography.body.bold())
                    + Text(" for staying active. Nice work!")
                    .foregroundColor(VivaDesign.Colors.primaryText)
                    .font(VivaDesign.Typography.body)
            } else {
                Text("\(opponentName) took this one, but you earned ")
                    .foregroundColor(VivaDesign.Colors.primaryText)
                    .font(VivaDesign.Typography.body)
                    + Text("\(rewardCoins) reward coins")
                    .foregroundColor(VivaDesign.Colors.vivaGreen)
                    .font(VivaDesign.Typography.body.bold())
                    + Text(" for staying active. Nice work!")
                    .foregroundColor(VivaDesign.Colors.primaryText)
                    .font(VivaDesign.Typography.body)
            }
            Spacer()
        }
    }
}
