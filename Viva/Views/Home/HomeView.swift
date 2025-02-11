import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @State private var selectedMatchup: Matchup?
    private let userSession: UserSession

    init(matchupService: MatchupService, userSession: UserSession) {
        _viewModel = StateObject(
            wrappedValue: HomeViewModel(matchupService: matchupService))
        self.userSession = userSession
    }

    var body: some View {
        VStack(spacing: VivaDesign.Spacing.medium) {
            HomeHeader()
                .padding(.top, VivaDesign.Spacing.small)
                .padding(.horizontal, VivaDesign.Spacing.medium)

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: VivaDesign.Spacing.medium) {
                        // Active Matchups Section
                        let activeMatchups = viewModel.matchups.filter {
                            $0.status == .active
                        }
                        HomeSection(
                            title: "Active Matchups",
                            emptyText: "No active matchups",
                            isEmpty: activeMatchups.isEmpty
                        ) {
                            VStack(spacing: VivaDesign.Spacing.small) {
                                ForEach(activeMatchups, id: \.id) { matchup in
                                    MatchupCard(matchup: matchup)
                                        .onTapGesture {
                                            selectedMatchup = matchup
                                        }
                                }
                            }
                        }

                        // Pending Matchups Section
                        let pendingMatchups = viewModel.matchups.filter {
                            $0.status == .pending
                        }
                        HomeSection(
                            title: "Pending Matchups",
                            emptyText: "No pending matchups",
                            isEmpty: pendingMatchups.isEmpty
                        ) {
                            VStack(spacing: VivaDesign.Spacing.small) {
                                ForEach(pendingMatchups, id: \.id) { matchup in
                                    MatchupCard(matchup: matchup)
                                        .onTapGesture {
                                            selectedMatchup = matchup
                                        }
                                }
                            }
                        }

                        // Pending Invitations Section
                        HomeSection(
                            title: "Pending Invitations",
                            emptyText: "No pending invitations",
                            isEmpty: viewModel.receivedInvites.isEmpty
                                && viewModel.sentInvites.isEmpty
                        ) {
                            VStack(spacing: VivaDesign.Spacing.medium) {
                                // Received Invites
                                if !viewModel.receivedInvites.isEmpty {
                                    VStack(spacing: VivaDesign.Spacing.small) {
                                        Text("Received")
                                            .font(VivaDesign.Typography.caption)
                                            .foregroundColor(
                                                VivaDesign.Colors.secondaryText
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
                                                userSession: userSession,
                                                onAccept: {},
                                                onDelete: {}
                                            )
                                        }
                                    }
                                }

                                // Sent Invites
                                if !viewModel.sentInvites.isEmpty {
                                    VStack(spacing: VivaDesign.Spacing.small) {
                                        Text("Sent")
                                            .font(VivaDesign.Typography.caption)
                                            .foregroundColor(
                                                VivaDesign.Colors.secondaryText
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
                                                userSession: userSession,
                                                onAccept: {},
                                                onDelete: {}
                                            )
                                        }
                                    }
                                }
                            }
                        }
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
            MatchupDetailView()
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
}

struct HomeHeader: View {
    var body: some View {
        HStack(spacing: VivaDesign.Spacing.medium) {
            LabeledValueStack(
                label: "Streak", value: "17 Wks", alignment: .leading)

            LabeledValueStack(
                label: "Points", value: "3,017", alignment: .leading)

            Spacer()

            VivaPrimaryButton(
                title: "Create New Matchup"
            ) {
                // Add action here
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
        userSession: userSession)
}
