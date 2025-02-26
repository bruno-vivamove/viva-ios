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
    @State private var selectedInvite: (user: User, inviteCode: String)? = nil
    @State private var showInviteView = false
    @State private var inviteSide: MatchupUser.Side?

    init(
        matchupService: MatchupService,
        friendService: FriendService,
        userService: UserService,
        userSession: UserSession,
        healthKitDataManager: HealthKitDataManager,
        matchupId: String
    ) {
        _viewModel = StateObject(
            wrappedValue: MatchupDetailViewModel(
                matchupService: matchupService,
                friendService: friendService,
                userService: userService,
                userSession: userSession,
                healthKitDataManager: healthKitDataManager,
                matchupId: matchupId
            ))
    }

    var body: some View {
        ZStack {
            // Main content
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let matchup = viewModel.matchup {
                    VStack(spacing: VivaDesign.Spacing.medium) {
                        MatchupHeader(
                            viewModel: viewModel,
                            onInviteTap: { user, inviteCode in
                                selectedInvite = (user, inviteCode)
                                showUnInviteSheet = true
                            },
                            onOpenPositionTap: { side in
                                inviteSide = side
                                showInviteView = true
                            }
                        )
                        .padding(.horizontal)

                        ViewToggle(isShowingTotal: $isShowingTotal)

                        let totalMatchupMeasurementPairs =
                            isShowingTotal
                            ? viewModel.totalMatchupMeasurementPairs
                            : viewModel.matchupMeasurementPairsByDay?.last

                        VStack(spacing: VivaDesign.Spacing.medium) {
                            ForEach(
                                Array(totalMatchupMeasurementPairs ?? [:]),
                                id: \.key
                            ) { type, measurementPair in
                                ComparisonRow(
                                    leftValue: viewModel.formatValue(
                                        measurementPair.leftValue, for: type),
                                    leftPoints: "\(measurementPair.leftPoints) pts",
                                    title: viewModel.displayName(for: type),
                                    rightValue: viewModel.formatValue(
                                        measurementPair.rightValue, for: type),
                                    rightPoints:
                                        "\(measurementPair.rightPoints) pts"
                                )
                            }
                        }
                        .padding(.horizontal, VivaDesign.Spacing.xlarge)

                        Spacer()

                        MatchupFooter(
                            endTime: matchup.endTime,
                            leftUser: matchup.leftUsers.first,
                            rightUser: matchup.rightUsers.first,
                            record: (wins: 0, losses: 0)
                        )
                        .padding(.horizontal)
                    }
                    .padding(.vertical, VivaDesign.Spacing.medium)
                }
            }
            .background(VivaDesign.Colors.background)
            
            // Overlay
//            if showUnInviteSheet, let invite = selectedInvite {
//                Color.black.opacity(0.4)
//                    .ignoresSafeArea()
//                    .onTapGesture {
//                        withAnimation(.easeInOut(duration: 0.2)) {
//                            showUnInviteSheet = false
//                            selectedInvite = nil
//                        }
//                    }
//
//                VStack(spacing: VivaDesign.Spacing.medium) {
//                    // User info
//                    HStack(spacing: VivaDesign.Spacing.medium) {
//                        VivaProfileImage(
//                            imageUrl: invite.user.imageUrl,
//                            size: .medium,
//                            isInvited: true
//                        )
//
//                        Text(invite.user.displayName)
//                            .font(VivaDesign.Typography.title2)
//                            .foregroundColor(VivaDesign.Colors.primaryText)
//                    }
//                    .padding(.top, VivaDesign.Spacing.medium)
//
//                    // Actions
//                    VStack(spacing: VivaDesign.Spacing.small) {
//                        Button {
//                            withAnimation(.easeInOut(duration: 0.2)) {
//                                showUnInviteSheet = false
//                                selectedInvite = nil
//                            }
//                            Task {
//                                await viewModel.deleteInvite(
//                                    inviteCode: invite.inviteCode)
//                            }
//                        } label: {
//                            HStack {
//                                Image(systemName: "xmark.circle.fill")
//                                Text("Cancel Invitation")
//                            }
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(VivaDesign.Colors.destructive)
//                            .foregroundColor(.white)
//                            .cornerRadius(8)
//                        }
//
//                        Button {
//                            withAnimation(.easeInOut(duration: 0.2)) {
//                                showUnInviteSheet = false
//                                selectedInvite = nil
//                            }
//                        } label: {
//                            Text("Dismiss")
//                                .frame(maxWidth: .infinity)
//                                .padding()
//                                .background(Color.gray.opacity(0.2))
//                                .foregroundColor(
//                                    VivaDesign.Colors.primaryText
//                                )
//                                .cornerRadius(8)
//                        }
//                    }
//                }
//                .padding()
//                .frame(width: 300)
//                .background(VivaDesign.Colors.background)
//                .cornerRadius(16)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 16)
//                        .stroke(Color.gray.opacity(0.4), lineWidth: 2)
//                )
//                .shadow(radius: 20)
//                .transition(.opacity.combined(with: .scale))
//            }
        }
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
        .task {
            await viewModel.loadData()
        }
        // TODO Bug - maybe
        .onChange(of: viewModel.matchup?.invites.count) { _, _ in
            if let matchup = viewModel.matchup {
                NotificationCenter.default.post(
                    name: .matchupUpdated,
                    object: matchup
                )
            }
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

struct MatchupHeader: View {
    let viewModel: MatchupDetailViewModel
    let onInviteTap: ((User, String) -> Void)?
    let onOpenPositionTap: ((MatchupUser.Side) -> Void)?

    var body: some View {
        HStack {
            UserScoreView(
                matchupUser: viewModel.matchup?.leftUsers.first,
                invitedUser: viewModel.matchup?.invites.first(where: {
                    $0.side == .left
                })?.user,
                inviteCode: viewModel.matchup?.invites.first(where: {
                    $0.side == .left
                })?.inviteCode,
                totalPoints: viewModel.totalPointsLeft ?? 0,
                imageOnLeft: true,
                onInviteTap: onInviteTap,
                onOpenPositionTap: {
                    onOpenPositionTap?(.left)
                }
            )
            Spacer()
            UserScoreView(
                matchupUser: viewModel.matchup?.rightUsers.first,
                invitedUser: viewModel.matchup?.invites.first(where: {
                    $0.side == .right
                })?.user,
                inviteCode: viewModel.matchup?.invites.first(where: {
                    $0.side == .right
                })?.inviteCode,
                totalPoints: viewModel.totalPointsRight ?? 0,
                imageOnLeft: false,
                onInviteTap: onInviteTap,
                onOpenPositionTap: {
                    onOpenPositionTap?(.right)
                }
            )
        }
    }
}

struct UserScoreView: View {
    let matchupUser: User?
    let invitedUser: User?
    let inviteCode: String?
    let totalPoints: Int
    let imageOnLeft: Bool
    let onInviteTap: ((User, String) -> Void)?
    let onOpenPositionTap: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            if imageOnLeft {
                userImage
                userInfo
            } else {
                userInfo
                userImage
            }
        }
    }

    private var userImage: some View {
        Group {
            if invitedUser != nil || matchupUser != nil {
                VivaProfileImage(
                    imageUrl: invitedUser?.imageUrl ?? matchupUser?.imageUrl,
                    size: .medium,
                    isInvited: invitedUser != nil
                )
                .onTapGesture {
                    if let user = invitedUser, let code = inviteCode {
                        onInviteTap?(user, code)
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
        LabeledValueStack(
            label: displayName,
            value: "\(totalPoints)",
            alignment: imageOnLeft ? .leading : .trailing
        )
        .lineLimit(1)
        .truncationMode(.tail)
    }

    private var displayName: String {
        if let invitedUser = invitedUser {
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

    var body: some View {
        HStack(spacing: VivaDesign.Spacing.xsmall) {
            Text("Total")
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundColor(
                    isShowingTotal
                        ? VivaDesign.Colors.primaryText
                        : VivaDesign.Colors.secondaryText)
            Text("|")
                .foregroundColor(VivaDesign.Colors.vivaGreen)
            Text("Today")
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundColor(
                    isShowingTotal
                        ? VivaDesign.Colors.secondaryText
                        : VivaDesign.Colors.primaryText)
        }
        .onTapGesture {
            withAnimation {
                isShowingTotal.toggle()
            }
        }
    }
}

struct ComparisonRow: View {
    let leftValue: String
    let leftPoints: String
    let title: String
    let rightValue: String
    let rightPoints: String

    var body: some View {
        VStack {
            HStack {
                // Left side with fixed width
                VStack(alignment: .leading) {
                    Text(leftValue)
                        .font(.title2)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundColor(VivaDesign.Colors.primaryText)
                    Text(leftPoints)
                        .font(VivaDesign.Typography.caption)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundColor(VivaDesign.Colors.secondaryText)
                }
                .frame(width: 80, alignment: .leading)  // Fixed width

                Spacer()

                // Center text with fixed position
                Text(title)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .font(.title2)
                    .foregroundColor(VivaDesign.Colors.vivaGreen)
                    .frame(width: 140, alignment: .center)  // Fixed width

                Spacer()

                // Right side with fixed width
                VStack(alignment: .trailing) {
                    Text(rightValue)
                        .font(.title2)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundColor(VivaDesign.Colors.primaryText)
                    Text(rightPoints)
                        .font(VivaDesign.Typography.caption)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundColor(VivaDesign.Colors.secondaryText)
                }
                .frame(width: 80, alignment: .trailing)  // Fixed width
            }

            VivaDivider()
        }
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

    var body: some View {
        HStack {
            // Left section
            VStack(spacing: VivaDesign.Spacing.small) {
                Spacer()
                Text("Matchup Ends")
                    .font(VivaDesign.Typography.caption)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(VivaDesign.Colors.primaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                TimeRemainingDisplay(endTime: endTime)
            }
            .frame(maxWidth: .infinity)

            Spacer()

            // Right section
            VStack(spacing: VivaDesign.Spacing.small) {
                Spacer()
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

struct TimeRemainingDisplay: View {
    let endTime: Date?

    var body: some View {
        if endTime == nil {
            HStack(spacing: VivaDesign.Spacing.xsmall) {
                Text("Not started")
                    .font(.title)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .foregroundColor(VivaDesign.Colors.primaryText)
        } else {
            let remainingTime = calculateTimeRemaining()
            HStack(spacing: VivaDesign.Spacing.xsmall) {
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
        HStack(spacing: VivaDesign.Spacing.xsmall) {
            VivaProfileImage(imageUrl: leftUser?.imageUrl, size: .mini)
            Text("\(wins)")
                .font(.title)
                .lineLimit(1)
            Spacer().frame(width: 10)
            Text("\(losses)")
                .font(.title)
                .lineLimit(1)
            VivaProfileImage(imageUrl: rightUser?.imageUrl, size: .mini)
        }
        .foregroundColor(VivaDesign.Colors.primaryText)
    }
}

#Preview {
    EmptyView()
}
