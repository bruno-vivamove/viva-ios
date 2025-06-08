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
        VStack(spacing: 0) {
            HomeHeader(
                userSession: userSession,
                viewModel: viewModel,
                matchupService: matchupService,
                friendService: friendService,
                userService: userService
            )
            .padding(.top, VivaDesign.Spacing.medium)
            .padding(.bottom, 0)
            .padding(.horizontal, VivaDesign.Spacing.screenPadding)

            if viewModel.isLoading && viewModel.isEmpty {
                LoadingView()
            } else if viewModel.isEmpty {
                // Empty state with refreshable list
                List {
                    HomeEmptyStateView()
                        .listRowBackground(VivaDesign.Colors.surface)
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
                .padding(.horizontal, VivaDesign.Spacing.screenPadding)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VivaDesign.Colors.background)
        .navigationDestination(item: $viewModel.selectedMatchup) { matchup in
            MatchupDetailView(
                matchupId: matchup.id,
                source: "home"
            )
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                if let vivaError = error as? VivaErrorResponse {
                    Text(vivaError.message)
                } else {
                    Text(error.localizedDescription)
                }
            }
        }
        .task {
            await viewModel.loadInitialDataIfNeeded()
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
            Image("crown_logo")
                .resizable()
                .scaledToFit()
                .frame(height: 40)
            Spacer(minLength: 1)
            CardButton(
                title: "Create Matchup",
                color: VivaDesign.Colors.primaryText
            ) {
                showMatchupCreation = true
            }
            .padding(.top, VivaDesign.Spacing.small)
        }
        .sheet(isPresented: $showMatchupCreation) {
            MatchupCategoriesView(
                matchupService: matchupService,
                friendService: friendService,
                userService: userService,
                userSession: userSession,
                showCreationFlow: $showMatchupCreation,
                source: "home"
            )
            .presentationBackground(.clear)
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

    var body: some View {
        List {
            // Completed Matchups
            if !viewModel.completedMatchups.isEmpty {
                MatchupSectionView(
                    title: "Final Matchups",
                    matchups: viewModel.completedMatchups,
                    lastRefreshTime: viewModel.dataLoadedTime,
                    onMatchupSelected: { matchup in
                        viewModel.selectedMatchup = matchup
                    },
                    matchupService: matchupService,
                    healthKitDataManager: healthKitDataManager,
                    userSession: userSession,
                    userMeasurementService: userMeasurementService
                )
            }

            // Active Matchups
            if !viewModel.activeMatchups.isEmpty {
                MatchupSectionView(
                    title: "Active Matchups",
                    matchups: viewModel.activeMatchups,
                    lastRefreshTime: viewModel.dataLoadedTime,
                    onMatchupSelected: { matchup in
                        viewModel.selectedMatchup = matchup
                    },
                    matchupService: matchupService,
                    healthKitDataManager: healthKitDataManager,
                    userSession: userSession,
                    userMeasurementService: userMeasurementService
                )
            }

            // Pending Matchups
            if !viewModel.pendingMatchups.isEmpty {
                MatchupSectionView(
                    title: "Pending Matchups",
                    matchups: viewModel.pendingMatchups,
                    lastRefreshTime: viewModel.dataLoadedTime,
                    onMatchupSelected: { matchup in
                        viewModel.selectedMatchup = matchup
                    },
                    matchupService: matchupService,
                    healthKitDataManager: healthKitDataManager,
                    userSession: userSession,
                    userMeasurementService: userMeasurementService
                )
            }

            if !viewModel.receivedInvites.isEmpty
                || !viewModel.sentInvites.isEmpty
            {
                PendingInvitesSection(
                    viewModel: viewModel
                )
            }
        }
    }
}

// MARK: - Pending Invites Section
struct PendingInvitesSection: View {
    @ObservedObject var viewModel: HomeViewModel

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
                ReceivedInvitesView(viewModel: viewModel)
            }

            // Sent Invites
            if !viewModel.sentInvites.isEmpty {
                SentInvitesView(viewModel: viewModel, rowInsets: EdgeInsets())
            }
        } header: {
            SectionHeaderView(title: "Pending Invites")
        }
    }
}

// MARK: - Received Invites View
struct ReceivedInvitesView: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        ForEach(viewModel.receivedInvites, id: \.inviteCode) { invite in
            UserActionCard(
                user: invite.sender,
                actions: [
                    UserActionCard.UserAction(
                        title: "Accept",
                        variant: .primary
                    ) { context in
                        Task {
                            await viewModel.acceptInvite(invite)
                            context.actionCompleted()
                        }
                    },
                    UserActionCard.UserAction(
                        title: "Decline",
                        variant: .secondary
                    ) { context in
                        Task {
                            await viewModel.deleteInvite(invite)
                            context.actionCompleted()
                        }
                    },
                ]
            )
            .listRowBackground(Color.clear)
            .buttonStyle(PlainButtonStyle())
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
            .padding(.bottom, VivaDesign.Spacing.componentSmall)
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
                    ?? UserSummary(
                        id: "",
                        displayName: "Open Invite",
                        caption: "",
                        imageUrl: nil,
                        friendStatus: .none
                    ),
                actions: [
                    UserActionCard.UserAction(
                        title: "Remind",
                        variant: .secondary
                    ) { context in
                        // Add remind functionality
                        context.actionCompleted()
                    },
                    UserActionCard.UserAction(
                        title: "Delete",
                        variant: .secondary
                    ) { context in
                        Task {
                            await viewModel.deleteInvite(invite)
                            context.actionCompleted()
                        }
                    },
                ]
            )
            .listRowBackground(Color.clear)
            .buttonStyle(PlainButtonStyle())
            .listRowSeparator(.hidden)
            .listRowInsets(rowInsets)
            .padding(.bottom, VivaDesign.Spacing.componentSmall)
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
