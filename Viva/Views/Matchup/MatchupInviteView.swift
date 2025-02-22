import SwiftUI

import SwiftUI

struct MatchupInviteView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var coordinator: MatchupInviteCoordinator
    @Binding var showCreationFlow: Bool
    @State private var searchText = ""
    @FocusState private var isSearchFieldFocused: Bool

    let matchupId: String
    let usersPerSide: Int

    init(
        matchupService: MatchupService,
        friendService: FriendService,
        userService: UserService,
        userSession: UserSession,
        matchupId: String,
        usersPerSide: Int,
        showCreationFlow: Binding<Bool>
    ) {
        self._coordinator = StateObject(
            wrappedValue: MatchupInviteCoordinator(
                matchupService: matchupService,
                friendService: friendService,
                userService: userService
            )
        )
        self.matchupId = matchupId
        self.usersPerSide = usersPerSide
        self._showCreationFlow = showCreationFlow
    }

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            VStack(spacing: VivaDesign.Spacing.large) {
                // Success Message
                VStack(spacing: VivaDesign.Spacing.medium) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(VivaDesign.Colors.vivaGreen)

                    Text("Matchup Created!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("Invite friends to join")
                        .font(.system(size: 18))
                        .foregroundColor(VivaDesign.Colors.secondaryText)
                }
                .padding(.top, 40)

                // Search bar
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
                                .foregroundColor(
                                    VivaDesign.Colors.secondaryText)
                        }
                    }
                }
                .padding(VivaDesign.Spacing.small)
                .background(
                    RoundedRectangle(
                        cornerRadius: VivaDesign.Sizing.cornerRadius
                    )
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
                .padding(.horizontal)

                if coordinator.isLoading {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: VivaDesign.Spacing.small) {
                            let usersToDisplay =
                                !searchText.isEmpty
                                ? coordinator.searchResults
                                : coordinator.friends

                            if usersToDisplay.isEmpty {
                                Spacer(minLength: 100)
                                if !searchText.isEmpty {
                                    // No search results
                                    VStack(spacing: VivaDesign.Spacing.medium) {
                                        Image(systemName: "person.slash")
                                            .font(.system(size: 40))
                                            .foregroundColor(
                                                VivaDesign.Colors.secondaryText)
                                        Text("No users found")
                                            .font(VivaDesign.Typography.body)
                                            .foregroundColor(
                                                VivaDesign.Colors.secondaryText)
                                        Text("Try a different search term")
                                            .font(VivaDesign.Typography.caption)
                                            .foregroundColor(
                                                VivaDesign.Colors.secondaryText)
                                    }
                                } else {
                                    // No friends
                                    VStack(spacing: VivaDesign.Spacing.medium) {
                                        Image(systemName: "person.2.circle")
                                            .font(.system(size: 40))
                                            .foregroundColor(
                                                VivaDesign.Colors.secondaryText)
                                        Text("No Friends Yet")
                                            .font(VivaDesign.Typography.body)
                                            .foregroundColor(
                                                VivaDesign.Colors.secondaryText)
                                        Text("Search to find users to invite")
                                            .font(VivaDesign.Typography.caption)
                                            .foregroundColor(
                                                VivaDesign.Colors.secondaryText)
                                    }
                                }
                                Spacer()
                            } else {
                                ForEach(usersToDisplay) { user in
                                    MatchupInviteCard(
                                        coordinator: coordinator,
                                        user: user,
                                        usersPerSide: usersPerSide,
                                        onInvite: { side in
                                            Task {
                                                await coordinator.inviteFriend(
                                                    userId: user.id,
                                                    matchupId: matchupId,
                                                    side: side
                                                )
                                            }
                                        },
                                        onCancel: {
                                            Task {
                                                await coordinator.deleteInvite(
                                                    userId: user.id,
                                                    matchupId: matchupId
                                                )
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Done Button
                Button("Done") {
                    showCreationFlow = false
                }
                .onDisappear {
                    // Notify HomeView of the new matchup
                    NotificationCenter.default.post(
                        name: .matchupCreated,
                        object: matchupId
                    )
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(VivaDesign.Colors.vivaGreen)
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await coordinator.loadData(matchupId: matchupId)
        }
        .onDisappear {
            coordinator.cleanup()
        }
    }
}

struct MatchupInviteCard: View {
    @ObservedObject var coordinator: MatchupInviteCoordinator
    let user: User
    let usersPerSide: Int
    let onInvite: (MatchupUser.Side) -> Void
    let onCancel: () -> Void  // New callback for canceling invites

    private var isInvited: Bool {
        coordinator.invitedFriends.contains(user.id)
    }

    private var canJoinLeftTeam: Bool {
        coordinator.hasOpenPosition(side: .left)
    }

    private var canJoinRightTeam: Bool {
        coordinator.hasOpenPosition(side: .right)
    }

    var body: some View {
        if isInvited {
            // Invited state with cancel option
            UserActionCard(
                user: user,
                actions: [
                    UserActionCard.UserAction(
                        title: "Cancel Invite",
                        variant: .secondary
                    ) {
                        onCancel()
                    }
                ]
            )
        } else if !canJoinLeftTeam && !canJoinRightTeam {
            // No positions state
            UserActionCard(
                user: user,
                actions: [
                    UserActionCard.UserAction(
                        title: "No Open Positions",
                        variant: .secondary
                    ) {
                        // No action, just showing status
                    }
                ]
            )
        } else {
            // Available positions state
            UserActionCard(
                user: user,
                actions: {
                    var actions: [UserActionCard.UserAction] = []
                    if canJoinLeftTeam {
                        actions.append(
                            UserActionCard.UserAction(
                                title: "Invite Teammate"
                            ) {
                                onInvite(.left)
                            }
                        )
                    }
                    if canJoinRightTeam {
                        actions.append(
                            UserActionCard.UserAction(
                                title: "Invite"
                            ) {
                                onInvite(.right)
                            }
                        )
                    }
                    return actions
                }()
            )
        }
    }
}
