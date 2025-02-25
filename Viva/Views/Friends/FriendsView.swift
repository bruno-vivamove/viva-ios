import SwiftUI

struct FriendsView: View {
    @StateObject private var viewModel: FriendsViewModel
    @State private var searchText = ""
    @State private var hasLoaded = false
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
        VStack(spacing: VivaDesign.Spacing.medium) {
            // Search bar with debouncing
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
            .padding(.horizontal, VivaDesign.Spacing.medium)

            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if viewModel.isSearchMode {
                // SEARCH RESULTS MODE
                if viewModel.searchResults.isEmpty {
                    // Empty search results
                    Spacer()
                    VStack(spacing: VivaDesign.Spacing.medium) {
                        Image(systemName: "person.slash")
                            .font(.system(size: 40))
                            .foregroundColor(VivaDesign.Colors.secondaryText)
                        Text("No users found")
                            .font(VivaDesign.Typography.body)
                            .foregroundColor(VivaDesign.Colors.secondaryText)
                        Text("Try a different search term")
                            .font(VivaDesign.Typography.caption)
                            .foregroundColor(VivaDesign.Colors.secondaryText)
                    }
                    Spacer()
                } else {
                    // Display search results
                    ScrollView {
                        VStack(spacing: VivaDesign.Spacing.small) {
                            ForEach(viewModel.searchResults) { user in
                                FriendRequestCard(
                                    viewModel: viewModel, user: user)
                            }
                        }
                        .padding(.horizontal, VivaDesign.Spacing.medium)
                    }
                }
            } else {
                // FRIENDS LIST MODE
                if viewModel.friends.isEmpty && viewModel.friendInvites.isEmpty
                    && viewModel.sentInvites.isEmpty
                {
                    // Empty friends state
                    VStack(spacing: VivaDesign.Spacing.medium) {
                        Spacer()
                        Image(systemName: "person.2.circle")
                            .font(.system(size: 50))
                            .foregroundColor(VivaDesign.Colors.secondaryText)
                        Text("No Friends Yet")
                            .font(VivaDesign.Typography.title3)
                            .foregroundColor(VivaDesign.Colors.primaryText)
                        Text("Search for people to add them as friends")
                            .font(VivaDesign.Typography.caption)
                            .foregroundColor(VivaDesign.Colors.secondaryText)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    List {
                        // Received Friend Invites Section
                        if !viewModel.friendInvites.isEmpty {
                            Section {
                                ForEach(viewModel.friendInvites) { user in
                                    FriendRequestCard(
                                        viewModel: viewModel, user: user)
                                }
                            } header: {
                                HStack {
                                    Text("Requests Received")
                                        .font(VivaDesign.Typography.header)
                                        .foregroundColor(.white)

                                    Text("(\(viewModel.friendInvites.count))")
                                        .font(VivaDesign.Typography.caption)
                                        .foregroundColor(
                                            VivaDesign.Colors.secondaryText)

                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.black)
                                .listRowInsets(EdgeInsets())
                            }
                        }

                        // Sent Friend Invites Section
                        if !viewModel.sentInvites.isEmpty {
                            Section {
                                ForEach(viewModel.sentInvites) { user in
                                    FriendRequestCard(
                                        viewModel: viewModel, user: user)
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
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.black)
                                .listRowInsets(EdgeInsets())
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
                                        userSession: viewModel.userSession)
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
                        await viewModel.loadFriendsData()
                    }
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
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
}

#Preview {
    let userSession = VivaAppObjects.dummyUserSession()
    let vivaAppObjects = VivaAppObjects(userSession: userSession)

    return FriendsView(
        matchupService: vivaAppObjects.matchupService,
        friendService: vivaAppObjects.friendService,
        userService: vivaAppObjects.userService,
        healthKitDataManager: vivaAppObjects.healthKitDataManager,
        userSession: userSession
    )
}
