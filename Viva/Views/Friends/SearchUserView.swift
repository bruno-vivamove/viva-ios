import SwiftUI

struct SearchUserView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SearchUserViewModel
    @State private var searchText = ""
    @FocusState private var isSearchFieldFocused: Bool
    
    init(userService: UserService, friendService: FriendService) {
        _viewModel = StateObject(
            wrappedValue: SearchUserViewModel(
                userService: userService,
                friendService: friendService
            ))
    }
    
    var body: some View {
        VStack(spacing: VivaDesign.Spacing.medium) {
            // Header with close button
            HStack {
                Text("Add Friend")
                    .font(VivaDesign.Typography.header)
                    .foregroundColor(VivaDesign.Colors.primaryText)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(VivaDesign.Colors.primaryText)
                }
            }
            .padding(.horizontal, VivaDesign.Spacing.medium)
            
            // Search bar with debouncing
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(VivaDesign.Colors.secondaryText)
                
                TextField("Search users", text: $searchText)
                    .foregroundColor(VivaDesign.Colors.primaryText)
                    .focused($isSearchFieldFocused)
                    .onChange(of: searchText) { oldValue, newValue in
                        viewModel.debouncedSearch(query: newValue)
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        Task {
                            await viewModel.clearResults()
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
            
            // Content area
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if viewModel.searchResultsQuery == nil {
                // Empty state - initial
                Spacer()
                VStack(spacing: VivaDesign.Spacing.medium) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(VivaDesign.Colors.secondaryText)
                    Text("Search for friends")
                        .font(VivaDesign.Typography.body)
                        .foregroundColor(VivaDesign.Colors.secondaryText)
                    Text("Find people by entering their name or email")
                        .font(VivaDesign.Typography.caption)
                        .foregroundColor(VivaDesign.Colors.secondaryText)
                }
                Spacer()
            } else if viewModel.searchResults.isEmpty {
                // Empty state - no results
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
                // Search results
                ScrollView {
                    VStack(spacing: VivaDesign.Spacing.small) {
                        ForEach(viewModel.searchResults) { user in
                            SearchUserCard(
                                user: user,
                                onSendRequest: {
                                    Task {
                                        await viewModel.sendFriendRequest(
                                            userId: user.id)
                                    }
                                },
                                onCancelRequest: {
                                    Task {
                                        await viewModel.cancelFriendRequest(
                                            userId: user.id)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, VivaDesign.Spacing.medium)
                }
            }
            
            // Error state
            if let error = viewModel.error {
                Text(error)
                    .foregroundColor(.red)
                    .font(VivaDesign.Typography.caption)
                    .padding()
            }
        }
        .background(VivaDesign.Colors.background)
        .onAppear {
            isSearchFieldFocused = true
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
}

#Preview {
    let userSession = VivaAppObjects.dummyUserSession()
    let networkClient = NetworkClient(
        settings: AppNetworkClientSettings(userSession: userSession))
    let userService = UserService(networkClient: networkClient)
    let friendService = FriendService(networkClient: networkClient)
    return SearchUserView(
        userService: userService,
        friendService: friendService
    )
}
