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
            } else {
                let activeMatchups = viewModel.matchups.filter {
                    $0.status == .active
                }
                let pendingMatchups = viewModel.matchups.filter {
                    $0.status == .pending
                }
                let hasReceivedInvites = !viewModel.receivedInvites.isEmpty
                let hasSentInvites = !viewModel.sentInvites.isEmpty

                ScrollView {
                    if activeMatchups.isEmpty && pendingMatchups.isEmpty
                        && !hasReceivedInvites && !hasSentInvites
                    {
                        VStack {
                            VStack(spacing: VivaDesign.Spacing.medium) {
                                Image(systemName: "trophy.circle")
                                    .font(.system(size: 50))
                                    .foregroundColor(
                                        VivaDesign.Colors.secondaryText)
                                Text("No Active Challenges")
                                    .font(VivaDesign.Typography.title3)
                                    .foregroundColor(
                                        VivaDesign.Colors.primaryText)
                                Text("Create a matchup to start competing")
                                    .font(VivaDesign.Typography.caption)
                                    .foregroundColor(
                                        VivaDesign.Colors.secondaryText)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .frame(minHeight: UIScreen.main.bounds.height - 200)
                    } else {
                        VStack(spacing: VivaDesign.Spacing.medium) {
                            // Active Matchups Section
                            if !activeMatchups.isEmpty {
                                HomeSection(
                                    title: "Active Matchups",
                                    emptyText: "",
                                    isEmpty: false
                                ) {
                                    VStack(spacing: VivaDesign.Spacing.small) {
                                        ForEach(activeMatchups, id: \.id) {
                                            matchup in
                                            MatchupCard(matchup: matchup)
                                                .onTapGesture {
                                                    selectedMatchup = matchup
                                                }
                                        }
                                    }
                                }
                            }

                            // Pending Matchups Section
                            if !pendingMatchups.isEmpty {
                                HomeSection(
                                    title: "Pending Matchups",
                                    emptyText: "",
                                    isEmpty: false
                                ) {
                                    VStack(spacing: VivaDesign.Spacing.small) {
                                        ForEach(pendingMatchups, id: \.id) {
                                            matchup in
                                            MatchupCard(matchup: matchup)
                                                .onTapGesture {
                                                    selectedMatchup = matchup
                                                }

                                        }
                                    }
                                }
                            }

                            // Pending Invitations Section
                            if hasReceivedInvites || hasSentInvites {
                                HomeSection(
                                    title: "Pending Invitations",
                                    emptyText: "",
                                    isEmpty: false
                                ) {
                                    VStack(spacing: VivaDesign.Spacing.medium) {
                                        if hasReceivedInvites {
                                            VStack(
                                                spacing: VivaDesign.Spacing
                                                    .small
                                            ) {
                                                Text("Received")
                                                    .font(
                                                        VivaDesign.Typography
                                                            .caption
                                                    )
                                                    .foregroundColor(
                                                        VivaDesign.Colors
                                                            .secondaryText
                                                    )
                                                    .frame(
                                                        maxWidth: .infinity,
                                                        alignment: .leading)

                                                ForEach(
                                                    viewModel.receivedInvites,
                                                    id: \.inviteCode
                                                ) { invite in
                                                    InvitationCard(
                                                        invite: invite,
                                                        userSession:
                                                            userSession,
                                                        onAccept: {
                                                            Task {
                                                                await
                                                                    handleAcceptInvite(
                                                                        invite)
                                                            }
                                                        },
                                                        onDelete: {
                                                            Task {
                                                                await
                                                                    handleDeleteInvite(
                                                                        invite)
                                                            }
                                                        }
                                                    )
                                                }
                                            }
                                        }

                                        if hasSentInvites {
                                            VStack(
                                                spacing: VivaDesign.Spacing
                                                    .small
                                            ) {
                                                Text("Sent")
                                                    .font(
                                                        VivaDesign.Typography
                                                            .caption
                                                    )
                                                    .foregroundColor(
                                                        VivaDesign.Colors
                                                            .secondaryText
                                                    )
                                                    .frame(
                                                        maxWidth: .infinity,
                                                        alignment: .leading)

                                                ForEach(
                                                    viewModel.sentInvites,
                                                    id: \.inviteCode
                                                ) { invite in
                                                    InvitationCard(
                                                        invite: invite,
                                                        userSession:
                                                            userSession,
                                                        onAccept: { /* Sent invites can't be accepted */
                                                        },
                                                        onDelete: {
                                                            Task {
                                                                await
                                                                    handleDeleteInvite(
                                                                        invite)
                                                            }
                                                        }
                                                    )
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, VivaDesign.Spacing.small)
                    }
                }
                .refreshable {
                    await viewModel.loadData()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VivaDesign.Colors.background)
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
            // Refresh all data after accepting
            await viewModel.loadData()
        } catch {
            viewModel.error = error
        }
    }

    private func handleDeleteInvite(_ invite: MatchupInvite) async {
        do {
            try await matchupService.deleteInvite(
                matchupId: invite.matchupId, inviteCode: invite.inviteCode)
            // Refresh all data after deleting
            await viewModel.loadData()
        } catch {
            viewModel.error = error
        }
    }

    private func handleCancelMatchup(_ matchup: Matchup) async {
        do {
            _ = try await matchupService.cancelMatchup(matchupId: matchup.id)
            // Refresh data after cancelling
            await viewModel.loadData()
        } catch {
            viewModel.error = error
        }
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
            LabeledValueStack(
                label: "Streak",
                value: "\(userSession.getUserProfile().streakDays) Days",
                alignment: .leading)

            LabeledValueStack(
                label: "Points",
                value: "\(userSession.getUserProfile().rewardPoints)",
                alignment: .leading)

            Spacer()

            VivaPrimaryButton(
                title: "Create New Matchup"
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
