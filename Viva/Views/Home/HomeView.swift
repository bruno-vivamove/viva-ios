import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @State private var selectedMatchup: Matchup?
    private let userSession: UserSession
    private let matchupService: MatchupService
    private let friendService: FriendService
    private let userService: UserService

    init(
        matchupService: MatchupService,
        userSession: UserSession,
        friendService: FriendService,
        userService: UserService
    ) {
        _viewModel = StateObject(
            wrappedValue: HomeViewModel(matchupService: matchupService))
        self.userSession = userSession
        self.matchupService = matchupService
        self.friendService = friendService
        self.userService = userService
    }

    var body: some View {
        VStack(spacing: VivaDesign.Spacing.medium) {
            HomeHeader(
                userSession: userSession,
                viewModel: viewModel,
                matchupService: matchupService,
                friendService: friendService,
                userService: userService
            )
            .padding(.top, VivaDesign.Spacing.small)
            .padding(.horizontal, VivaDesign.Spacing.medium)

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.isEmpty {
                EmptyStateView()
            } else {
                List {
                    Section {
                        // This empty section creates padding at the top
                    }
                    .listSectionSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    // Active Matchups
                    if !viewModel.activeMatchups.isEmpty {
                        Section {
                            ForEach(viewModel.activeMatchups) { matchup in
                                MatchupCard(matchup: matchup, onCancel: nil)
                                    .onTapGesture {
                                        selectedMatchup = matchup
                                    }
                                    .listRowInsets(
                                        EdgeInsets(
                                            top: 4, leading: 16, bottom: 4,
                                            trailing: 16)
                                    )
                                    .listRowBackground(Color.clear)
                            }
                        } header: {
                            HStack {
                                Text("Active Matchups")
                                    .font(VivaDesign.Typography.header)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black)
                            .listRowInsets(EdgeInsets())
                        }
                    }

                    // Pending Matchups
                    if !viewModel.pendingMatchups.isEmpty {
                        Section {
                            ForEach(viewModel.pendingMatchups) { matchup in
                                MatchupCard(matchup: matchup) {
                                    Task {
                                        await handleCancelMatchup(matchup)
                                    }
                                }
                                .onTapGesture {
                                    selectedMatchup = matchup
                                }
                                .listRowInsets(
                                    EdgeInsets(
                                        top: 4, leading: 16, bottom: 4,
                                        trailing: 16)
                                )
                                .listRowBackground(Color.clear)
                            }
                        } header: {
                            HStack {
                                Text("Pending Matchups")
                                    .font(VivaDesign.Typography.header)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black)
                            .listRowInsets(EdgeInsets())
                        }
                    }

                    if !viewModel.receivedInvites.isEmpty
                        || !viewModel.sentInvites.isEmpty
                    {
                        // Pending Invitations
                        Section {
                            // Received Invites
                            if !viewModel.receivedInvites.isEmpty {
                                ForEach(viewModel.receivedInvites, id: \.inviteCode) { invite in
                                    UserActionCard(
                                        user: invite.user ?? User(id: "", displayName: "Open Invite", imageUrl: nil, friendStatus: .none),
                                        actions: [
                                            UserActionCard.UserAction(
                                                title: "Accept",
                                                variant: .primary
                                            ) {
                                                Task {
                                                    await handleAcceptInvite(invite)
                                                }
                                            },
                                            UserActionCard.UserAction(
                                                title: "Delete",
                                                variant: .secondary
                                            ) {
                                                Task {
                                                    await handleDeleteInvite(invite)
                                                }
                                            }
                                        ]
                                    )
                                    .listRowBackground(Color.clear)
                                    .buttonStyle(PlainButtonStyle()) // Removes button-like behavior
                                }
                            }

                            // Sent Invites
                            if !viewModel.sentInvites.isEmpty {
                                ForEach(viewModel.sentInvites, id: \.inviteCode) { invite in
                                    UserActionCard(
                                        user: invite.user ?? User(id: "", displayName: "Open Invite", imageUrl: nil, friendStatus: .none),
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
                                                    await handleDeleteInvite(invite)
                                                }
                                            }
                                        ]
                                    )
                                    .listRowBackground(Color.clear)
                                    .buttonStyle(PlainButtonStyle()) // Removes button-like behavior
                                }
                            }
                        } header: {
                            HStack {
                                Text("Pending Invites")
                                    .font(VivaDesign.Typography.header)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black)
                            .listRowInsets(EdgeInsets())
                        }
                    }

                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
                .refreshable {
                    await viewModel.loadData()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            Task {
                await viewModel.loadInitialDataIfNeeded()
            }
        }
        .sheet(item: $selectedMatchup) { matchup in
            MatchupDetailView(
                matchupService: matchupService,
                matchupId: matchup.id
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
    }

    private func handleAcceptInvite(_ invite: MatchupInvite) async {
        do {
            try await matchupService.acceptInvite(inviteCode: invite.inviteCode)
            await viewModel.loadData()
        } catch {
            viewModel.error = error
        }
    }

    private func handleDeleteInvite(_ invite: MatchupInvite) async {
        do {
            try await viewModel.removeInvite(invite)
        } catch {
            viewModel.error = error
        }
    }

    private func handleCancelMatchup(_ matchup: Matchup) async {
        do {
            // Remove matchup and its associated invites
            try await viewModel.removeMatchup(matchup)
        } catch {
            viewModel.error = error
        }
    }
}

extension Matchup: Equatable {
    static func == (lhs: Matchup, rhs: Matchup) -> Bool {
        lhs.id == rhs.id
    }
}

// Empty State View
struct EmptyStateView: View {
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

// ViewModel Extension
extension HomeViewModel {
    var isEmpty: Bool {
        matchups.isEmpty && receivedInvites.isEmpty && sentInvites.isEmpty
    }

    var activeMatchups: [Matchup] {
        matchups.filter { $0.status == .active }
    }

    var pendingMatchups: [Matchup] {
        matchups.filter { $0.status == .pending }
    }

    var allInvites: [MatchupInvite] {
        receivedInvites + sentInvites
    }

    var hasInvites: Bool {
        !receivedInvites.isEmpty || !sentInvites.isEmpty
    }
}

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

            VivaPrimaryButton(
                title: "Create Matchup"
            ) {
                showMatchupCreation = true
            }
        }
        .fullScreenCover(isPresented: $showMatchupCreation) {
            MatchupCategoriesView(
                matchupService: matchupService,
                friendService: friendService,
                userService: userService,
                userSession: userSession,
                showCreationFlow: $showMatchupCreation
            )
        }
        .onChange(of: showMatchupCreation) { _, isShowing in
            if !isShowing {
                // Refresh data when matchup creation is dismissed
                Task {
                    await viewModel.loadData()
                }
            }
        }
    }
}

struct HomeSection<Content: View>: View {
    let title: String
    let emptyText: String
    let content: Content
    let isEmpty: Bool

    init(
        title: String,
        emptyText: String,
        isEmpty: Bool,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.emptyText = emptyText
        self.isEmpty = isEmpty
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: VivaDesign.Spacing.small) {
            HStack {
                Text(title)
                    .font(VivaDesign.Typography.header)
                    .foregroundColor(VivaDesign.Colors.primaryText)
                Spacer()
            }

            if isEmpty {
                HStack {
                    Text(emptyText)
                        .foregroundColor(VivaDesign.Colors.secondaryText)
                    Spacer()
                }
            } else {
                content
            }
        }
        .padding(.horizontal, VivaDesign.Spacing.medium)
    }
}

#Preview {
    let userSession = VivaAppObjects.dummyUserSession()
    let vivaAppObjects = VivaAppObjects(userSession: userSession)

    HomeView(
        matchupService: MatchupService(
            networkClient: NetworkClient(
                settings: vivaAppObjects.appNetworkClientSettings)),
        userSession: userSession,
        friendService: vivaAppObjects.friendService,
        userService: vivaAppObjects.userService
    )
}
