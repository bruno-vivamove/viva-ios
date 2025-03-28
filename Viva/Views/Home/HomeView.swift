import Foundation
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var userSession: UserSession
    @EnvironmentObject var friendService: FriendService
    @EnvironmentObject var matchupService: MatchupService
    @EnvironmentObject var userService: UserService
    @EnvironmentObject var healthKitDataManager: HealthKitDataManager
    @EnvironmentObject var userMeasurementService: UserMeasurementService

    @StateObject private var viewModel: HomeViewModel

    init(viewModel: HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HomeHeader(
                    userSession: userSession,
                    viewModel: viewModel,
                    matchupService: matchupService,
                    friendService: friendService,
                    userService: userService
                )
                .padding(VivaDesign.Spacing.outerPadding)
                .padding(.bottom, 0)

                if viewModel.isLoading && viewModel.isEmpty {
                    LoadingView()
                } else if viewModel.isEmpty {
                    // Empty state with refreshable list
                    List {
                        HomeEmptyStateView()
                            .listRowBackground(Color.black)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets())
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        await viewModel.loadData()
                    }
                } else {
                    HomeContentList(
                        viewModel: viewModel,
                        matchupService: matchupService,
                        healthKitDataManager: healthKitDataManager,
                        userSession: userSession,
                        userMeasurementService: userMeasurementService
                    )
                    .listRowInsets(EdgeInsets())
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        await viewModel.loadData()
                    }
                    .listSectionSpacing(0)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
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
                    )
                )
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadInitialDataIfNeeded()
                }
            }
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Home Header
struct HomeHeader: View {
    @ObservedObject var userSession: UserSession
    @ObservedObject var viewModel: HomeViewModel
    @State private var showMatchupCreation = false

    let matchupService: MatchupService
    let friendService: FriendService
    let userService: UserService

    var body: some View {
        HStack(spacing: VivaDesign.Spacing.medium) {
            StreakCounter(streakDays: userSession.userProfile?.streakDays ?? 0)
            Spacer(minLength: 1)
            CardButton(
                title: "Create Matchup",
                color: VivaDesign.Colors.primaryText
            ) {
                showMatchupCreation = true
            }
        }
        .sheet(isPresented: $showMatchupCreation) {
            MatchupCategoriesView(
                matchupService: matchupService,
                friendService: friendService,
                userService: userService,
                userSession: userSession,
                showCreationFlow: $showMatchupCreation
            )
            .presentationBackground(.clear)
        }
    }
}

// MARK: - Streak Counter
struct StreakCounter: View {
    let streakDays: Int

    var body: some View {
        VStack(alignment: .center) {
            Text("\(streakDays)")
                .foregroundColor(VivaDesign.Colors.primaryText)
                .font(VivaDesign.Typography.value)
                .lineLimit(1)
            Text("Week Streak")
                .foregroundColor(VivaDesign.Colors.vivaGreen)
                .font(VivaDesign.Typography.caption)
                .lineLimit(1)
        }
    }
}

// MARK: - Home Content List
struct HomeContentList: View {
    @ObservedObject var viewModel: HomeViewModel
    let matchupService: MatchupService
    let healthKitDataManager: HealthKitDataManager
    let userSession: UserSession
    let userMeasurementService: UserMeasurementService

    private let rowInsets = EdgeInsets(
        top: 0,
        leading: VivaDesign.Spacing.outerPadding,
        bottom: VivaDesign.Spacing.small,
        trailing: VivaDesign.Spacing.outerPadding
    )

    var body: some View {
        List {
            // Active Matchups
            if !viewModel.activeMatchups.isEmpty {
                ActiveMatchupsSection(
                    viewModel: viewModel,
                    matchupService: matchupService,
                    healthKitDataManager: healthKitDataManager,
                    userSession: userSession,
                    userMeasurementService: userMeasurementService,
                    rowInsets: rowInsets
                )
            }

            // Pending Matchups
            if !viewModel.pendingMatchups.isEmpty {
                PendingMatchupsSection(
                    viewModel: viewModel,
                    matchupService: matchupService,
                    healthKitDataManager: healthKitDataManager,
                    userSession: userSession,
                    userMeasurementService: userMeasurementService,
                    rowInsets: rowInsets
                )
            }

            if !viewModel.receivedInvites.isEmpty
                || !viewModel.sentInvites.isEmpty
            {
                PendingInvitesSection(
                    viewModel: viewModel,
                    rowInsets: rowInsets
                )
            }
            
            // Completed Matchups
            if !viewModel.completedMatchups.isEmpty {
                CompletedMatchupsSection(
                    viewModel: viewModel,
                    matchupService: matchupService,
                    healthKitDataManager: healthKitDataManager,
                    userSession: userSession,
                    userMeasurementService: userMeasurementService,
                    rowInsets: rowInsets
                )
            }
        }
    }
}

// MARK: - Active Matchups Section
struct ActiveMatchupsSection: View {
    @ObservedObject var viewModel: HomeViewModel
    let matchupService: MatchupService
    let healthKitDataManager: HealthKitDataManager
    let userSession: UserSession
    let userMeasurementService: UserMeasurementService
    let rowInsets: EdgeInsets

    var body: some View {
        Section {
            ForEach(viewModel.activeMatchups) { matchup in
                MatchupCard(
                    matchupId: matchup.id,
                    matchupService: matchupService,
                    userMeasurementService: userMeasurementService,
                    healthKitDataManager: healthKitDataManager,
                    userSession: userSession,
                    lastRefreshTime: viewModel.dataRefreshedTime
                )
                .id(matchup.id)
                .onTapGesture {
                    viewModel.selectedMatchup = matchup
                }
                .listRowSeparator(.hidden)
                .listRowInsets(rowInsets)
            }
        } header: {
            SectionHeaderView(title: "Active Matchups")
        }
    }
}

// MARK: - Pending Matchups Section
struct PendingMatchupsSection: View {
    @ObservedObject var viewModel: HomeViewModel
    let matchupService: MatchupService
    let healthKitDataManager: HealthKitDataManager
    let userSession: UserSession
    let userMeasurementService: UserMeasurementService
    let rowInsets: EdgeInsets

    var body: some View {
        Section {
            ForEach(viewModel.pendingMatchups) { matchup in
                MatchupCard(
                    matchupId: matchup.id,
                    matchupService: matchupService,
                    userMeasurementService: userMeasurementService,
                    healthKitDataManager: healthKitDataManager,
                    userSession: userSession,
                    lastRefreshTime: viewModel.dataRefreshedTime
                )
                .id(matchup.id)
                .onTapGesture {
                    viewModel.selectedMatchup = matchup
                }
                .listRowSeparator(.hidden)
                .listRowInsets(rowInsets)
            }
        } header: {
            SectionHeaderView(title: "Pending Matchups")
        }
    }
}

// MARK: - Completed Matchups Section
struct CompletedMatchupsSection: View {
    @ObservedObject var viewModel: HomeViewModel
    let matchupService: MatchupService
    let healthKitDataManager: HealthKitDataManager
    let userSession: UserSession
    let userMeasurementService: UserMeasurementService
    let rowInsets: EdgeInsets

    var body: some View {
        Section {
            ForEach(viewModel.completedMatchups) { matchup in
                MatchupCard(
                    matchupId: matchup.id,
                    matchupService: matchupService,
                    userMeasurementService: userMeasurementService,
                    healthKitDataManager: healthKitDataManager,
                    userSession: userSession,
                    lastRefreshTime: viewModel.dataRefreshedTime
                )
                .id(matchup.id)
                .onTapGesture {
                    viewModel.selectedMatchup = matchup
                }
                .listRowSeparator(.hidden)
                .listRowInsets(rowInsets)
            }
        } header: {
            SectionHeaderView(title: "Completed Matchups")
        }
    }
}


// MARK: - Pending Invites Section
struct PendingInvitesSection: View {
    @ObservedObject var viewModel: HomeViewModel
    let rowInsets: EdgeInsets

    private let headerInsets = EdgeInsets(
        top: 0,
        leading: VivaDesign.Spacing.medium,
        bottom: VivaDesign.Spacing.small,
        trailing: VivaDesign.Spacing.medium
    )

    var body: some View {
        Section {
            // Received Invites
            if !viewModel.receivedInvites.isEmpty {
                ReceivedInvitesView(viewModel: viewModel, rowInsets: rowInsets)
            }

            // Sent Invites
            if !viewModel.sentInvites.isEmpty {
                SentInvitesView(viewModel: viewModel, rowInsets: rowInsets)
            }
        } header: {
            ZStack {
                Rectangle()
                    .fill(Color.black)
                    .frame(maxWidth: .infinity)

                HStack {
                    Text("Pending Invites")
                        .font(VivaDesign.Typography.header)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(headerInsets)
            }
            .listRowInsets(EdgeInsets())
        }
    }
}

// MARK: - Received Invites View
struct ReceivedInvitesView: View {
    @ObservedObject var viewModel: HomeViewModel
    let rowInsets: EdgeInsets

    var body: some View {
        ForEach(viewModel.receivedInvites, id: \.inviteCode) { invite in
            UserActionCard(
                user: invite.sender,
                actions: [
                    UserActionCard.UserAction(
                        title: "Accept",
                        variant: .primary
                    ) {
                        Task {
                            await viewModel.acceptInvite(invite)
                        }
                    },
                    UserActionCard.UserAction(
                        title: "Decline",
                        variant: .secondary
                    ) {
                        Task {
                            await viewModel.deleteInvite(invite)
                        }
                    },
                ]
            )
            .listRowBackground(Color.clear)
            .buttonStyle(PlainButtonStyle())
            .listRowSeparator(.hidden)
            .listRowInsets(rowInsets)
        }
    }
}

// MARK: - Sent Invites View
struct SentInvitesView: View {
    @ObservedObject var viewModel: HomeViewModel
    let rowInsets: EdgeInsets

    var body: some View {
        ForEach(viewModel.sentInvites, id: \.inviteCode) { invite in
            UserActionCard(
                user: invite.user
                    ?? User(
                        id: "",
                        displayName: "Open Invite",
                        imageUrl: nil,
                        friendStatus: .none),
                actions: [
                    UserActionCard.UserAction(
                        title: "Remind",
                        variant: .primary
                    ) {
                        // Add remind functionality
                    },
                    UserActionCard.UserAction(
                        title: "Delete",
                        variant: .secondary
                    ) {
                        Task {
                            await viewModel.deleteInvite(invite)
                        }
                    },
                ]
            )
            .listRowBackground(Color.clear)
            .buttonStyle(PlainButtonStyle())
            .listRowSeparator(.hidden)
            .listRowInsets(rowInsets)
        }
    }
}

// MARK: - Empty State View
struct HomeEmptyStateView: View {
    var body: some View {
        VStack {
            VStack(spacing: VivaDesign.Spacing.medium) {
                Image(systemName: "trophy.circle")
                    .font(.system(size: 50))
                    .foregroundColor(VivaDesign.Colors.secondaryText)
                Text("No Active Challenges")
                    .font(VivaDesign.Typography.title3)
                    .foregroundColor(VivaDesign.Colors.primaryText)
                Text("Create a matchup to start competing")
                    .font(VivaDesign.Typography.caption)
                    .foregroundColor(VivaDesign.Colors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: UIScreen.main.bounds.height - 200)
    }
}
