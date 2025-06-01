import SwiftUI

struct FriendsView: View {
    @EnvironmentObject var userSession: UserSession
    @EnvironmentObject var friendService: FriendService
    @EnvironmentObject var matchupService: MatchupService
    @EnvironmentObject var userService: UserService
    @EnvironmentObject var healthKitDataManager: HealthKitDataManager
    @EnvironmentObject var userMeasurementService: UserMeasurementService

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
    @FocusState private var isSearchFieldFocused: Bool

    init(viewModel: FriendsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Header
                FriendsHeader(
                    searchText: $viewModel.searchText, viewModel: viewModel,
                    isSearchFieldFocused: _isSearchFieldFocused
                )
                .padding(.top, VivaDesign.Spacing.medium)
                .padding(.bottom, 0)
                .padding(.horizontal, VivaDesign.Spacing.outerPadding)

                if viewModel.isSearchMode {
                    // SEARCH RESULTS MODE
                    if viewModel.searchResults.isEmpty {
                        // Empty search results - use similar layout to HomeEmptyStateView
                        FriendsEmptySearchView()
                            .padding(.vertical, VivaDesign.Spacing.medium)
                    } else {
                        // Display search results in a List for consistency
                        List {
                            Section {
                                ForEach(viewModel.searchResults) { user in
                                    FriendRequestCard(
                                        viewModel: viewModel, user: user,
                                        selectedUserId: $viewModel.selectedUserId
                                    )
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets())
                                    .padding(.bottom, VivaDesign.Spacing.cardSpacing)
                                }
                            } header: {
                                SectionHeaderView(title: "Search Results")
                            }
                        }
                        .listStyle(PlainListStyle())
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, VivaDesign.Spacing.outerPadding)
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
                        List {
                            FriendsEmptyStateView()
                                .listRowBackground(Color.black)
                                .listRowInsets(EdgeInsets())
                        }
                        .listStyle(PlainListStyle())
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, VivaDesign.Spacing.outerPadding)
                        .refreshable {
                            await viewModel.loadFriendsData()
                        }
                    } else {
                        List {
                            // Received Friend Invites Section
                            if !viewModel.friendInvites.isEmpty {
                                Section {
                                    ForEach(viewModel.friendInvites) { user in
                                        FriendRequestCard(
                                            viewModel: viewModel, user: user,
                                            selectedUserId: $viewModel.selectedUserId
                                        )
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets())
                                        .padding(.bottom, VivaDesign.Spacing.cardSpacing)
                                    }
                                } header: {
                                    SectionHeaderView(
                                        title: "Requests Received",
                                        subtitle:
                                            "(\(viewModel.friendInvites.count))"
                                    )
                                }
                            }

                            // Sent Friend Invites Section
                            if !viewModel.sentInvites.isEmpty {
                                Section {
                                    ForEach(viewModel.sentInvites) { user in
                                        FriendRequestCard(
                                            viewModel: viewModel, user: user,
                                            selectedUserId: $viewModel.selectedUserId
                                        )
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets())
                                        .padding(.bottom, VivaDesign.Spacing.cardSpacing)
                                    }
                                } header: {
                                    SectionHeaderView(
                                        title: "Requests Sent",
                                        subtitle: "(\(viewModel.sentInvites.count))"
                                    )
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
                                            userSession: viewModel.userSession,
                                            selectedUserId: $viewModel.selectedUserId
                                        )
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets())
                                        .padding(.bottom, VivaDesign.Spacing.cardSpacing)
                                    }
                                } header: {
                                    SectionHeaderView(
                                        title: "Current Friends",
                                        subtitle: "(\(viewModel.friends.count))"
                                    )
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
                        .padding(.horizontal, VivaDesign.Spacing.outerPadding)
                    }
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
                    ),
                    source: "friends"
                )
            }
            // Add NavigationLink for profile navigation
            .navigationDestination(isPresented: Binding(
                get: { viewModel.selectedUserId != nil },
                set: { if !$0 { viewModel.selectedUserId = nil } }
            )) {
                if let userId = viewModel.selectedUserId {
                    ProfileView(
                        viewModel: ProfileViewModel(
                            userId: userId,
                            userSession: userSession,
                            userService: userService,
                            matchupService: matchupService
                        )
                    )
                }
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
            .onDisappear {
                viewModel.cleanup()
            }
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
                    viewModel.debouncedSearch()
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
