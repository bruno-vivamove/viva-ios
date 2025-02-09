import SwiftUI

struct FriendsView: View {
    @StateObject private var viewModel: FriendsViewModel
    @State private var showSearchSheet = false
    @State private var hasLoaded = false

    let friendService: FriendService

    init(friendService: FriendService, userSession: UserSession) {
        _viewModel = StateObject(
            wrappedValue: FriendsViewModel(
                friendService: friendService,
                userSession: userSession
            ))
        self.friendService = friendService
    }

    var body: some View {
        VStack(spacing: VivaDesign.Spacing.medium) {
            // Header with Add Friend button
            HStack {
                Text("Friends")
                    .font(VivaDesign.Typography.header)
                    .foregroundColor(VivaDesign.Colors.primaryText)

                Spacer()

                VivaPrimaryButton(title: "Add Friend") {
                    showSearchSheet = true
                }
            }
            .padding(.horizontal, VivaDesign.Spacing.medium)

            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    // Main content container with leading alignment
                    VStack(
                        alignment: .leading, spacing: VivaDesign.Spacing.large
                    ) {
                        // Friend Invites Section
                        if !viewModel.friendInvites.isEmpty {
                            VStack(
                                alignment: .leading,
                                spacing: VivaDesign.Spacing.small
                            ) {
                                Text("Friend Invites")
                                    .font(VivaDesign.Typography.title3)
                                    .foregroundColor(
                                        VivaDesign.Colors.vivaGreen
                                    )
                                    .padding(
                                        .horizontal, VivaDesign.Spacing.medium)

                                VStack(spacing: VivaDesign.Spacing.small) {
                                    ForEach(viewModel.friendInvites) { user in
                                        FriendInviteCard(
                                            user: user,
                                            onAccept: {
                                                Task {
                                                    await viewModel
                                                        .acceptFriendRequest(
                                                            userId: user.id)
                                                }
                                            },
                                            onDecline: {
                                                Task {
                                                    await viewModel
                                                        .declineFriendRequest(
                                                            userId: user.id)
                                                }
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, VivaDesign.Spacing.medium)
                            }
                        }

                        // Current Friends Section with frame modifier
                        VStack(
                            alignment: .leading,
                            spacing: VivaDesign.Spacing.small
                        ) {
                            HStack {
                                Text("Current Friends")
                                    .font(VivaDesign.Typography.title3)
                                    .foregroundColor(
                                        VivaDesign.Colors.vivaGreen)

                                Text("(\(viewModel.friends.count))")
                                    .font(VivaDesign.Typography.caption)
                                    .foregroundColor(
                                        VivaDesign.Colors.secondaryText)
                            }
                            .padding(.horizontal, VivaDesign.Spacing.medium)

                            if viewModel.friends.isEmpty {
                                Text("No friends added yet")
                                    .font(VivaDesign.Typography.body)
                                    .foregroundColor(
                                        VivaDesign.Colors.secondaryText
                                    )
                                    .padding(
                                        .horizontal, VivaDesign.Spacing.medium)
                            } else {
                                VStack(spacing: VivaDesign.Spacing.small) {
                                    ForEach(viewModel.friends) { user in
                                        FriendCard(user: user)
                                    }
                                }
                                .padding(.horizontal, VivaDesign.Spacing.medium)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, VivaDesign.Spacing.small)
                }
                .refreshable {
                    await viewModel.loadData()
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
        .background(VivaDesign.Colors.background)
        .onAppear {
            if !hasLoaded {
                hasLoaded = true
                Task {
                    await viewModel.loadData()
                }
            }
        }
        .sheet(isPresented: $showSearchSheet) {
            SearchUserView(
                userService: UserService(
                    networkClient: NetworkClient(
                        settings: AppNetworkClientSettings(
                            userSession: viewModel.userSession))),
                friendService: friendService
            )
        }
    }
}

#Preview {
    let userSession = VivaAppObjects.dummyUserSession()
    let networkClient = NetworkClient(
        settings: AppNetworkClientSettings(userSession: userSession))
    let friendService = FriendService(networkClient: networkClient)
    return FriendsView(friendService: friendService, userSession: userSession)
}
