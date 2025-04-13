import SwiftUI

struct MatchupInviteView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var coordinator: MatchupInviteCoordinator
    @Binding var showCreationFlow: Bool
    @State private var searchText = ""
    @State private var showHeader = true // New state to control header visibility
    @FocusState private var isSearchFieldFocused: Bool
    
    let isInvitingFromDetails: Bool
    let preferredTeamId: String?
    let matchup: MatchupDetails
    let usersPerSide: Int
    let source: String

    init(
        matchupService: MatchupService,
        friendService: FriendService,
        userService: UserService,
        userSession: UserSession,
        matchup: MatchupDetails,
        usersPerSide: Int,
        showCreationFlow: Binding<Bool>,
        isInvitingFromDetails: Bool = false,
        preferredTeamId: String? = nil,
        source: String = "default"
    ) {
        self._coordinator = StateObject(
            wrappedValue: MatchupInviteCoordinator(
                matchupService: matchupService,
                friendService: friendService,
                userService: userService
            )
        )
        self.matchup = matchup
        self.usersPerSide = usersPerSide
        self._showCreationFlow = showCreationFlow
        self.isInvitingFromDetails = isInvitingFromDetails
        
        // Convert preferred side to team ID if provided
        self.preferredTeamId = preferredTeamId
        self.source = source
    }

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header (animates away when results appear)
                        if showHeader {
                            headerSection
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                                .padding(.bottom, 20)
                                .background(Color.black)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        // Content
                        LazyVStack(spacing: VivaDesign.Spacing.small, pinnedViews: .sectionHeaders) {
                            Section {
                                if coordinator.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 40)
                                } else {
                                    if coordinator.usersToDisplay.isEmpty {
                                        InviteEmptyStateView(showingSearchResults: !searchText.isEmpty)
                                    } else {
                                        ForEach(coordinator.usersToDisplay) { user in
                                            MatchupInviteCard(
                                                coordinator: coordinator,
                                                user: user,
                                                matchup: matchup
                                            )
                                            .padding(.horizontal)
                                        }
                                    }
                                }
                            } header: {
                                searchBar
                                    .background(Color.black)
                            }
                        }
                    }
                }

                // Done Button
                AuthButtonView(title: "Done", style: .primary) {
                    if isInvitingFromDetails {
                        dismiss()
                    } else {
                        showCreationFlow = false
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 20)
                .background(Color.black)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await coordinator.loadData(matchupId: matchup.id)
            if let teamId = preferredTeamId {
                coordinator.setPreferredTeamId(teamId)
            }
        }
        .onChange(of: isSearchFieldFocused) { oldValue, newValue in
            withAnimation(.easeOut) {
                showHeader = false
            }
        }
        .onDisappear {
            coordinator.cleanup()
            NotificationCenter.default.post(
                name: .matchupCreationFlowCompleted,
                object: self.matchup,
                userInfo: ["source": source]
            )
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: VivaDesign.Spacing.medium) {
            if !isInvitingFromDetails {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(VivaDesign.Colors.vivaGreen)

                Text("Matchup Created!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text("Invite friends to join")
                    .font(.system(size: 18))
                    .foregroundColor(VivaDesign.Colors.secondaryText)
            } else {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 40))
                    .foregroundColor(VivaDesign.Colors.vivaGreen)

                Text("Invite Opponent")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                Text("Search for friends to invite")
                    .font(.system(size: 16))
                    .foregroundColor(VivaDesign.Colors.secondaryText)
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(VivaDesign.Colors.secondaryText)

            TextField("Search users", text: $searchText)
                .foregroundColor(VivaDesign.Colors.primaryText)
                .focused($isSearchFieldFocused)
                .onChange(of: searchText) { oldValue, newValue in
                    coordinator.debouncedSearch(query: newValue)
                }

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    Task {
                        coordinator.searchResults = []
                        coordinator.searchQuery = nil
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(VivaDesign.Colors.secondaryText)
                }
            }
        }
        .padding(VivaDesign.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: VivaDesign.Sizing.cornerRadius)
                .fill(VivaDesign.Colors.background)
                .overlay(
                    RoundedRectangle(cornerRadius: VivaDesign.Sizing.cornerRadius)
                        .stroke(VivaDesign.Colors.divider, lineWidth: VivaDesign.Sizing.borderWidth)
                )
        )
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

private struct InviteEmptyStateView: View {
    let showingSearchResults: Bool

    var body: some View {
        VStack(spacing: VivaDesign.Spacing.medium) {
            Image(systemName: showingSearchResults ? "person.slash" : "person.2.circle")
                .font(.system(size: 40))
                .foregroundColor(VivaDesign.Colors.secondaryText)

            Text(showingSearchResults ? "No users found" : "No Friends Yet")
                .font(VivaDesign.Typography.body)
                .foregroundColor(VivaDesign.Colors.secondaryText)

            Text(showingSearchResults ? "Try a different search term" : "Search to find users to invite")
                .font(VivaDesign.Typography.caption)
                .foregroundColor(VivaDesign.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}
