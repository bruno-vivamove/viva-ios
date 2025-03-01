import SwiftUI

struct FriendsView: View {
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

    @StateObject private var viewModel: FriendsViewModel
    @State private var searchText = ""
    @State private var hasLoaded = false
    @State private var selectedMatchup: Matchup?
    @FocusState private var isSearchFieldFocused: Bool

    let friendService: FriendService
    let matchupService: MatchupService
    let userService: UserService
    let healthKitDataManager: HealthKitDataManager

    init(
        matchupService: MatchupService,
        friendService: FriendService,
        userService: UserService,
        healthKitDataManager: HealthKitDataManager,
        userSession: UserSession
    ) {
        self.matchupService = matchupService
        self.friendService = friendService
        self.userService = userService
        self.healthKitDataManager = healthKitDataManager
        _viewModel = StateObject(
            wrappedValue: FriendsViewModel(
                friendService: friendService,
                userService: userService,
                userSession: userSession
            ))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search Header
            FriendsHeader(
                searchText: $searchText, viewModel: viewModel,
                isSearchFieldFocused: _isSearchFieldFocused
            )
            .padding(VivaDesign.Spacing.medium)
            .padding(.bottom, 0)

            if viewModel.isSearchMode {
                // SEARCH RESULTS MODE
                if viewModel.searchResults.isEmpty {
                    // Empty search results - use similar layout to HomeEmptyStateView
                    FriendsEmptySearchView()
                        .padding(VivaDesign.Spacing.medium)
                } else {
                    // Display search results in a List for consistency
                    List {
                        Section {
                            ForEach(viewModel.searchResults) { user in
                                FriendRequestCard(
                                    viewModel: viewModel, user: user
                                )
                                .listRowSeparator(.hidden)
                                .listRowInsets(rowInsets)
                            }
                        } header: {
                            HStack {
                                Text("Search Results")
                                    .font(VivaDesign.Typography.header)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .background(Color.black)
                            .listRowInsets(headerInsets)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                }
            } else {
                // FRIENDS LIST MODE
                let isViewEmpty =
                    viewModel.friends.isEmpty
                    && viewModel.friendInvites.isEmpty
                    && viewModel.sentInvites.isEmpty

                if viewModel.isLoading && isViewEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if isViewEmpty {
                    // Empty friends state - use similar layout to HomeEmptyStateView
                    FriendsEmptyStateView()
                        .padding(VivaDesign.Spacing.medium)
                } else {
                    List {
                        // Received Friend Invites Section
                        if !viewModel.friendInvites.isEmpty {
                            Section {
                                ForEach(viewModel.friendInvites) { user in
                                    FriendRequestCard(
                                        viewModel: viewModel, user: user
                                    )
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(rowInsets)
                                }
                            } header: {
                                HStack {
                                    Text("Requests Received")
                                        .font(VivaDesign.Typography.header)
                                        .foregroundColor(.white)
                                    Text(
                                        "(\(viewModel.friendInvites.count))"
                                    )
                                    .font(VivaDesign.Typography.caption)
                                    .foregroundColor(
                                        VivaDesign.Colors.secondaryText)
                                    Spacer()
                                }
                                .background(Color.black)
                                .listRowInsets(headerInsets)
                            }
                        }

                        // Sent Friend Invites Section
                        if !viewModel.sentInvites.isEmpty {
                            Section {
                                ForEach(viewModel.sentInvites) { user in
                                    FriendRequestCard(
                                        viewModel: viewModel, user: user
                                    )
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(rowInsets)
                                }
                            } header: {
                                HStack {
                                    Text("Requests Sent")
                                        .font(VivaDesign.Typography.header)
                                        .foregroundColor(.white)
                                    Text("(\(viewModel.sentInvites.count))")
                                        .font(VivaDesign.Typography.caption)
                                        .foregroundColor(
                                            VivaDesign.Colors.secondaryText)
                                    Spacer()
                                }
                                .background(Color.black)
                                .listRowInsets(headerInsets)
                            }
                        }

                        // Current Friends Section
                        if !viewModel.friends.isEmpty {
                            Section {
                                ForEach(viewModel.friends) { user in
                                    FriendCard(
                                        user: user,
                                        matchupService: matchupService,
                                        friendService: friendService,
                                        userService: userService,
                                        healthKitDataManager:
                                            healthKitDataManager,
                                        userSession: viewModel.userSession
                                    )
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(rowInsets)
                                }
                            } header: {
                                HStack {
                                    Text("Current Friends")
                                        .font(VivaDesign.Typography.header)
                                        .foregroundColor(.white)
                                    Text("(\(viewModel.friends.count))")
                                        .font(VivaDesign.Typography.caption)
                                        .foregroundColor(
                                            VivaDesign.Colors.secondaryText)
                                    Spacer()
                                }
                                .background(Color.black)
                                .listRowInsets(headerInsets)
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        await viewModel.loadFriendsData()
                    }
                    .listSectionSpacing(0)

                }
            }

            if let error = viewModel.error {
                Text(error)
                    .foregroundColor(.red)
                    .font(VivaDesign.Typography.caption)
                    .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .sheet(item: $selectedMatchup) { matchup in
            NavigationView {
                MatchupDetailView(
                    matchupService: matchupService,
                    friendService: friendService,
                    userService: userService,
                    userSession: viewModel.userSession,
                    healthKitDataManager: healthKitDataManager,
                    matchupId: matchup.id
                )
            }
        }
        .onAppear {
            if !hasLoaded {
                hasLoaded = true
                Task {
                    await viewModel.loadFriendsData()
                }
            }

            // Observe friend request sent notifications
            NotificationCenter.default.addObserver(
                forName: .friendRequestSent,
                object: nil,
                queue: .main
            ) { notification in
                if let sentUser = notification.object as? User {
                    Task { @MainActor in
                        // Add the user to sent invites if not already present
                        if !viewModel.sentInvites.contains(where: {
                            $0.id == sentUser.id
                        }) {
                            viewModel.sentInvites.append(sentUser)
                        }
                    }
                }
            }

            // Observe matchup creation notifications
            NotificationCenter.default.addObserver(
                forName: .friendScreenMatchupCreationCompleted,
                object: nil,
                queue: .main
            ) { notification in
                if let matchupDetails = notification.object as? MatchupDetails {
                    Task {
                        await MainActor.run {
                            selectedMatchup = matchupDetails.asMatchup
                        }
                    }
                }
            }
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
}

// Search Header View for consistency with HomeHeader
struct FriendsHeader: View {
    @Binding var searchText: String
    @ObservedObject var viewModel: FriendsViewModel
    @FocusState var isSearchFieldFocused: Bool

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(VivaDesign.Colors.secondaryText)

            TextField("Search for friends", text: $searchText)
                .foregroundColor(VivaDesign.Colors.primaryText)
                .focused($isSearchFieldFocused)
                .onChange(of: searchText) { oldValue, newValue in
                    viewModel.debouncedSearch(query: newValue)
                }

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    Task {
                        await viewModel.clearSearchResults()
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
                    RoundedRectangle(
                        cornerRadius: VivaDesign.Sizing.cornerRadius
                    )
                    .stroke(
                        VivaDesign.Colors.divider,
                        lineWidth: VivaDesign.Sizing.borderWidth)
                )
        )
    }
}

// Empty Search View - similar to HomeEmptyStateView
struct FriendsEmptySearchView: View {
    var body: some View {
        VStack {
            VStack(spacing: VivaDesign.Spacing.medium) {
                Image(systemName: "person.slash")
                    .font(.system(size: 50))
                    .foregroundColor(VivaDesign.Colors.secondaryText)
                Text("No users found")
                    .font(VivaDesign.Typography.title3)
                    .foregroundColor(VivaDesign.Colors.primaryText)
                Text("Try a different search term")
                    .font(VivaDesign.Typography.caption)
                    .foregroundColor(VivaDesign.Colors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: UIScreen.main.bounds.height - 200)
    }
}

// Empty Friends State View - similar to HomeEmptyStateView
struct FriendsEmptyStateView: View {
    var body: some View {
        VStack {
            VStack(spacing: VivaDesign.Spacing.medium) {
                Image(systemName: "person.2.circle")
                    .font(.system(size: 50))
                    .foregroundColor(VivaDesign.Colors.secondaryText)
                Text("No Friends Yet")
                    .font(VivaDesign.Typography.title3)
                    .foregroundColor(VivaDesign.Colors.primaryText)
                Text("Search for people to add them as friends")
                    .font(VivaDesign.Typography.caption)
                    .foregroundColor(VivaDesign.Colors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: UIScreen.main.bounds.height - 200)
    }
}
