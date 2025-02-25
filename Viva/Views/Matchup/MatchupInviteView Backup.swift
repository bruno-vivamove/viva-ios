import SwiftUI

//struct MatchupInviteViewBackup: View {
//    @Environment(\.dismiss) private var dismiss
//    @StateObject private var coordinator: MatchupInviteCoordinator
//    @Binding var showCreationFlow: Bool
//    @State private var searchText = ""
//    @FocusState private var isSearchFieldFocused: Bool
//    let isInvitingFromDetails: Bool
//    let preferredSide: MatchupUser.Side?
//    let matchupId: String
//    let usersPerSide: Int
//    let onInviteSent: (() -> Void)?
//
//    init(
//        matchupService: MatchupService,
//        friendService: FriendService,
//        userService: UserService,
//        userSession: UserSession,
//        matchupId: String,
//        usersPerSide: Int,
//        showCreationFlow: Binding<Bool>,
//        isInvitingFromDetails: Bool = false,
//        preferredSide: MatchupUser.Side? = nil,
//        onInviteSent: (() -> Void)? = nil
//    ) {
//        self._coordinator = StateObject(
//            wrappedValue: MatchupInviteCoordinator(
//                matchupService: matchupService,
//                friendService: friendService,
//                userService: userService
//            )
//        )
//        self.matchupId = matchupId
//        self.usersPerSide = usersPerSide
//        self._showCreationFlow = showCreationFlow
//        self.isInvitingFromDetails = isInvitingFromDetails
//        self.preferredSide = preferredSide
//        self.onInviteSent = onInviteSent
//    }
//
//    var body: some View {
//        ZStack {
//            Color.black.edgesIgnoringSafeArea(.all)
//
//            VStack(spacing: 0) {
//                ScrollView(showsIndicators: false) {
//                    VStack(spacing: 0) {
//                        // Header (scrolls off screen)
//                        headerSection
//                            .frame(maxWidth: .infinity)
//                            .padding(.top, 40)
//                            .padding(.bottom, 20)
//                            .background(Color.black)
//                        
//                        // Content
//                        LazyVStack(spacing: VivaDesign.Spacing.small, pinnedViews: .sectionHeaders) {
//                            Section {
//                                if coordinator.isLoading {
//                                    ProgressView()
//                                        .tint(.white)
//                                        .frame(maxWidth: .infinity)
//                                        .padding(.vertical, 40)
//                                } else {
//                                    let usersToDisplay = !searchText.isEmpty ? coordinator.searchResults : coordinator.friends
//                                    
//                                    if usersToDisplay.isEmpty {
//                                        InviteEmptyStateView(showingSearchResults: !searchText.isEmpty)
//                                    } else {
//                                        ForEach(usersToDisplay) { user in
//                                            MatchupInviteCard(
//                                                coordinator: coordinator,
//                                                user: user,
//                                                usersPerSide: usersPerSide,
//                                                onInvite: { side in
//                                                    Task {
//                                                        await coordinator.inviteFriend(
//                                                            userId: user.id,
//                                                            matchupId: matchupId,
//                                                            side: side ?? preferredSide
//                                                        )
//                                                        await MainActor.run {
//                                                            onInviteSent?()
//                                                        }
//                                                    }
//                                                },
//                                                onCancel: {
//                                                    Task {
//                                                        await coordinator.deleteInvite(
//                                                            userId: user.id,
//                                                            matchupId: matchupId
//                                                        )
//                                                    }
//                                                }
//                                            )
//                                            .padding(.horizontal)
//                                        }
//                                    }
//                                }
//                            } header: {
//                                // Search bar (sticks to top)
//                                searchBar
//                                    .background(Color.black)
//                            }
//                        }
//                    }
//                }
//
//                // Done Button
//                AuthButtonView(title: "Done", style: .primary) {
//                    if isInvitingFromDetails {
//                        dismiss()
//                    } else {
//                        showCreationFlow = false
//                    }
//                }
//                .padding(.horizontal)
//                .padding(.vertical, 20)
//                .background(Color.black)
//            }
//        }
//        .navigationBarBackButtonHidden(true)
//        .task {
//            await coordinator.loadData(matchupId: matchupId)
//            if let side = preferredSide {
//                coordinator.setPreferredSide(side)
//            }
//        }
//        .onDisappear {
//            coordinator.cleanup()
//            if !isInvitingFromDetails {
//                NotificationCenter.default.post(
//                    name: .matchupCreated,
//                    object: matchupId
//                )
//            }
//        }
//    }
//    
//    private var headerSection: some View {
//        VStack(spacing: VivaDesign.Spacing.medium) {
//            if !isInvitingFromDetails {
//                Image(systemName: "checkmark.circle.fill")
//                    .font(.system(size: 60))
//                    .foregroundColor(VivaDesign.Colors.vivaGreen)
//
//                Text("Matchup Created!")
//                    .font(.system(size: 28, weight: .bold))
//                    .foregroundColor(.white)
//
//                Text("Invite friends to join")
//                    .font(.system(size: 18))
//                    .foregroundColor(VivaDesign.Colors.secondaryText)
//            } else {
//                Image(systemName: "person.badge.plus")
//                    .font(.system(size: 40))
//                    .foregroundColor(VivaDesign.Colors.vivaGreen)
//
//                Text("Invite Opponent")
//                    .font(.system(size: 24, weight: .bold))
//                    .foregroundColor(.white)
//
//                Text("Search for friends to invite")
//                    .font(.system(size: 16))
//                    .foregroundColor(VivaDesign.Colors.secondaryText)
//            }
//        }
//    }
//    
//    private var searchBar: some View {
//        HStack {
//            Image(systemName: "magnifyingglass")
//                .foregroundColor(VivaDesign.Colors.secondaryText)
//
//            TextField("Search users", text: $searchText)
//                .foregroundColor(VivaDesign.Colors.primaryText)
//                .focused($isSearchFieldFocused)
//                .onChange(of: searchText) { oldValue, newValue in
//                    coordinator.debouncedSearch(query: newValue)
//                }
//
//            if !searchText.isEmpty {
//                Button(action: {
//                    searchText = ""
//                    Task {
//                        coordinator.searchResults = []
//                        coordinator.searchQuery = nil
//                    }
//                }) {
//                    Image(systemName: "xmark.circle.fill")
//                        .foregroundColor(VivaDesign.Colors.secondaryText)
//                }
//            }
//        }
//        .padding(VivaDesign.Spacing.small)
//        .background(
//            RoundedRectangle(cornerRadius: VivaDesign.Sizing.cornerRadius)
//                .fill(VivaDesign.Colors.background)
//                .overlay(
//                    RoundedRectangle(cornerRadius: VivaDesign.Sizing.cornerRadius)
//                        .stroke(VivaDesign.Colors.divider, lineWidth: VivaDesign.Sizing.borderWidth)
//                )
//        )
//        .padding(.horizontal)
//        .padding(.vertical, 8)
//    }
//}
//
//private struct InviteEmptyStateView: View {
//    let showingSearchResults: Bool
//
//    var body: some View {
//        VStack(spacing: VivaDesign.Spacing.medium) {
//            Image(systemName: showingSearchResults ? "person.slash" : "person.2.circle")
//                .font(.system(size: 40))
//                .foregroundColor(VivaDesign.Colors.secondaryText)
//
//            Text(showingSearchResults ? "No users found" : "No Friends Yet")
//                .font(VivaDesign.Typography.body)
//                .foregroundColor(VivaDesign.Colors.secondaryText)
//
//            Text(showingSearchResults ? "Try a different search term" : "Search to find users to invite")
//                .font(VivaDesign.Typography.caption)
//                .foregroundColor(VivaDesign.Colors.secondaryText)
//        }
//        .frame(maxWidth: .infinity)
//        .padding(.vertical, 60)
//    }
//}
