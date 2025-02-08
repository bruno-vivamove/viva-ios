import SwiftUI

struct FriendsView: View {
    @StateObject private var viewModel: FriendsViewModel
    
    init(friendService: FriendService) {
        _viewModel = StateObject(wrappedValue: FriendsViewModel(friendService: friendService))
    }
    
    var body: some View {
        VStack(spacing: VivaDesign.Spacing.medium) {
            // Header
            Text("Friends")
                .font(VivaDesign.Typography.header)
                .foregroundColor(VivaDesign.Colors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, VivaDesign.Spacing.medium)
            
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    RefreshControl(coordinateSpace: .named("RefreshControl")) {
                        await viewModel.loadData()
                    }
                    VStack(spacing: VivaDesign.Spacing.large) {
                        // Friend Invites Section
                        if !viewModel.friendInvites.isEmpty {
                            VStack(alignment: .leading, spacing: VivaDesign.Spacing.small) {
                                Text("Friend Invites")
                                    .font(VivaDesign.Typography.title3)
                                    .foregroundColor(VivaDesign.Colors.vivaGreen)
                                    .padding(.horizontal, VivaDesign.Spacing.medium)
                                
                                VStack(spacing: VivaDesign.Spacing.small) {
                                    ForEach(viewModel.friendInvites) { user in
                                        FriendInviteCard(
                                            user: user,
                                            onAccept: {
                                                Task {
                                                    await viewModel.acceptFriendRequest(userId: user.id)
                                                }
                                            },
                                            onDecline: {
                                                Task {
                                                    await viewModel.declineFriendRequest(userId: user.id)
                                                }
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, VivaDesign.Spacing.medium)
                            }
                        }
                        
                        // Current Friends Section
                        VStack(alignment: .leading, spacing: VivaDesign.Spacing.small) {
                            HStack {
                                Text("Current Friends")
                                    .font(VivaDesign.Typography.title3)
                                    .foregroundColor(VivaDesign.Colors.vivaGreen)
                                
                                Text("(\(viewModel.friends.count))")
                                    .font(VivaDesign.Typography.caption)
                                    .foregroundColor(VivaDesign.Colors.secondaryText)
                            }
                            .padding(.horizontal, VivaDesign.Spacing.medium)
                            
                            VStack(spacing: VivaDesign.Spacing.small) {
                                ForEach(viewModel.friends) { user in
                                    FriendCard(user: user)
                                }
                            }
                            .padding(.horizontal, VivaDesign.Spacing.medium)
                        }
                    }
                    .padding(.vertical, VivaDesign.Spacing.small)
                }
                .coordinateSpace(name: "RefreshControl")
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
        .task {
            await viewModel.loadData()
        }
    }
}

struct FriendInviteCard: View {
    let user: User
    let onAccept: () -> Void
    let onDecline: () -> Void
    private let buttonWidth: CGFloat = 100
    
    var body: some View {
        VivaCard {
            HStack {
                // User Info
                HStack(spacing: VivaDesign.Spacing.small) {
                    VivaProfileImage(
                        imageUrl: user.imageUrl,
                        size: .small
                    )
                    
                    Text(user.displayName)
                        .foregroundColor(VivaDesign.Colors.primaryText)
                        .font(VivaDesign.Typography.body)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: VivaDesign.Spacing.minimal) {
                    VivaPrimaryButton(
                        title: "Accept",
                        width: buttonWidth,
                        action: onAccept
                    )
                    
                    VivaSecondaryButton(
                        title: "Decline",
                        width: buttonWidth,
                        action: onDecline
                    )
                }
            }
        }
    }
}

struct FriendCard: View {
    let user: User
    
    var body: some View {
        VivaCard {
            HStack {
                // User Info
                HStack(spacing: VivaDesign.Spacing.small) {
                    VivaProfileImage(
                        imageUrl: user.imageUrl,
                        size: .small
                    )
                    
                    Text(user.displayName)
                        .foregroundColor(VivaDesign.Colors.primaryText)
                        .font(VivaDesign.Typography.body)
                }
                
                Spacer()
                
                // Challenge Button
                VivaPrimaryButton(
                    title: "Challenge",
                    width: 100
                ) {
                    // Add challenge action
                }
            }
        }
    }
}

#Preview {
    let networkClient = NetworkClient(settings: AppWithNoSessionNetworkClientSettings())
    let friendService = FriendService(networkClient: networkClient)
    return FriendsView(friendService: friendService)
}
