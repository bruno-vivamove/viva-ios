import Foundation
import SwiftUI

struct HomeView: View {
    private let headerInsets = EdgeInsets(
        top: 0,
        leading: VivaDesign.Spacing.medium,
        bottom: VivaDesign.Spacing.small,
        trailing: VivaDesign.Spacing.medium
    )

    private let rowInsets = EdgeInsets(
        top: 0,
        leading: VivaDesign.Spacing.medium,
        bottom: VivaDesign.Spacing.small,
        trailing: VivaDesign.Spacing.medium
    )

    @StateObject private var viewModel: HomeViewModel
    
    // A counter to trigger refresh for MatchupCards
    @State private var refreshTrigger = 0

    private let userSession: UserSession
    private let matchupService: MatchupService
    private let friendService: FriendService
    private let userService: UserService
    private let healthKitDataManager: HealthKitDataManager

    init(
        matchupService: MatchupService,
        userSession: UserSession,
        friendService: FriendService,
        userService: UserService,
        healthKitDataManager: HealthKitDataManager
    ) {
        _viewModel = StateObject(
            wrappedValue: HomeViewModel(
                userSession: userSession, matchupService: matchupService))
        self.userSession = userSession
        self.matchupService = matchupService
        self.friendService = friendService
        self.userService = userService
        self.healthKitDataManager = healthKitDataManager
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
            .padding(VivaDesign.Spacing.medium)
            .padding(.bottom, 0)

            if viewModel.isLoading && viewModel.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.isEmpty {
                HomeEmptyStateView()
                    .padding(VivaDesign.Spacing.medium)
            } else {
                List {
                    // Active Matchups
                    if !viewModel.activeMatchups.isEmpty {
                        Section {
                            ForEach(viewModel.activeMatchups) { matchup in
                                MatchupCard(
                                    matchupId: matchup.id,
                                    matchupService: matchupService,
                                    healthKitDataManager: healthKitDataManager,
                                    userSession: userSession
                                )
                                .id("active-\(matchup.id)-\(refreshTrigger)") // Force redraw on refresh
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

                    // Pending Matchups
                    if !viewModel.pendingMatchups.isEmpty {
                        Section {
                            ForEach(viewModel.pendingMatchups) { matchup in
                                MatchupCard(
                                    matchupId: matchup.id,
                                    matchupService: matchupService,
                                    healthKitDataManager: healthKitDataManager,
                                    userSession: userSession
                                )
                                .id("pending-\(matchup.id)-\(refreshTrigger)") // Force redraw on refresh
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

                    if !viewModel.receivedInvites.isEmpty
                        || !viewModel.sentInvites.isEmpty
                    {
                        // Pending Invitations section
                        Section {
                            // Received Invites
                            if !viewModel.receivedInvites.isEmpty {
                                ForEach(
                                    viewModel.receivedInvites, id: \.inviteCode
                                ) { invite in
                                    UserActionCard(
                                        user: invite.sender,
                                        actions: [
                                            UserActionCard.UserAction(
                                                title: "Accept",
                                                variant: .primary
                                            ) {
                                                Task {
                                                    await viewModel
                                                        .acceptInvite(
                                                            invite)
                                                }
                                            },
                                            UserActionCard.UserAction(
                                                title: "Decline",
                                                variant: .secondary
                                            ) {
                                                Task {
                                                    await viewModel.deleteInvite(
                                                        invite)
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

                            // Sent Invites
                            if !viewModel.sentInvites.isEmpty {
                                ForEach(viewModel.sentInvites, id: \.inviteCode)
                                { invite in
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
                                                    await viewModel
                                                        .deleteInvite(
                                                            invite)
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
                .listRowInsets(EdgeInsets())
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
                .refreshable {
                    await viewModel.loadData()
                    // Increment the refresh trigger to force recreating MatchupCards
                    refreshTrigger += 1
                }
                .listSectionSpacing(0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .sheet(item: $viewModel.selectedMatchup) { matchup in
            NavigationView {
                MatchupDetailView(
                    matchupService: matchupService,
                    friendService: friendService,
                    userService: userService,
                    userSession: userSession,
                    healthKitDataManager: healthKitDataManager,
                    matchupId: matchup.id
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
            }
        }
        .onAppear {
            Task {
                await viewModel.loadInitialDataIfNeeded()
            }
        }
    }
}

// Empty State View
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

// HomeHeader
struct HomeHeader: View {
    @ObservedObject var userSession: UserSession
    @ObservedObject var viewModel: HomeViewModel
    @State private var showMatchupCreation = false
    let matchupService: MatchupService
    let friendService: FriendService
    let userService: UserService

    var body: some View {
        HStack(spacing: VivaDesign.Spacing.medium) {
            VStack(alignment: .center) {
                Text("\(userSession.getUserProfile().streakDays)")
                    .foregroundColor(VivaDesign.Colors.primaryText)
                    .font(VivaDesign.Typography.value)
                    .lineLimit(1)
                Text("Week Streak")
                    .foregroundColor(VivaDesign.Colors.vivaGreen)
                    .font(VivaDesign.Typography.caption)
                    .lineLimit(1)
            }

            VStack(alignment: .center) {
                Text("\(userSession.getUserProfile().rewardPoints)")
                    .foregroundColor(VivaDesign.Colors.primaryText)
                    .font(VivaDesign.Typography.value)
                    .lineLimit(1)
                Text("Points")
                    .foregroundColor(VivaDesign.Colors.vivaGreen)
                    .font(VivaDesign.Typography.caption)
                    .lineLimit(1)
            }

            Spacer()

            CardButton(
                title: "Create Matchup"
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
        }
    }
}
