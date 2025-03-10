import SwiftUI

struct MatchupCard: View {
    @EnvironmentObject var userSession: UserSession
    @StateObject private var viewModel: MatchupCardViewModel
    
    // Add this property to trigger updates
    var lastRefreshTime: Date?

    init(
        matchupId: String,
        matchupService: MatchupService,
        healthKitDataManager: HealthKitDataManager,
        userSession: UserSession,
        lastRefreshTime: Date? = nil
    ) {
        self.lastRefreshTime = lastRefreshTime
        _viewModel = StateObject(
            wrappedValue: MatchupCardViewModel(
                matchupId: matchupId,
                matchupService: matchupService,
                healthKitDataManager: healthKitDataManager,
                userSession: userSession,
                lastRefreshTime: lastRefreshTime
            ))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.matchupDetails == nil {
                loadingView
            } else if let details = viewModel.matchupDetails {
                matchupCardView(details)
            } else {
                errorView
            }
        }
        .background(Color.black)
        .listRowBackground(Color.clear)
        // Add this modifier to observe changes to lastRefreshTime
        .onChange(of: lastRefreshTime) { oldValue, newValue in
            viewModel.updateLastRefreshTime(newValue)
        }
    }

    private var loadingView: some View {
        VivaCard {
            HStack {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                Spacer()
            }
            .padding()
        }
    }

    private var errorView: some View {
        VivaCard {
            VStack {
                Text("Unable to load matchup")
                    .foregroundColor(VivaDesign.Colors.secondaryText)
                Button("Retry") {
                    Task {
                        await viewModel.loadMatchupDetails()
                    }
                }
                .padding(.top, VivaDesign.Spacing.small)
            }
            .padding()
        }
    }

    private func matchupCardView(_ details: MatchupDetails) -> some View {
        VivaCard {
            HStack(spacing: 0) {
                // Left side container - aligned to left edge
                HStack(spacing: VivaDesign.Spacing.small) {
                    let user = details.leftUsers.first
                    let invite = details.invites.first { invite in
                        invite.side == .left
                    }

                    VivaProfileImage(
                        userId: invite?.user?.id ?? user?.id,
                        imageUrl: invite?.user?.imageUrl ?? user?.imageUrl,
                        size: .small,
                        isInvited: invite != nil
                    )

                    VStack(alignment: .leading) {
                        Text(getUserDisplayName(user: user, invite: invite))
                            .foregroundColor(VivaDesign.Colors.vivaGreen)
                            .font(VivaDesign.Typography.caption)
                            .lineLimit(1)
                        Text("\(details.leftSidePoints)")
                            .foregroundColor(VivaDesign.Colors.primaryText)
                            .font(VivaDesign.Typography.value)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)  // Push content to left edge
                }

                // Centered divider with fixed width container
                HStack {
                    Text("|")
                        .foregroundColor(VivaDesign.Colors.secondaryText)
                        .font(VivaDesign.Typography.title3)
                }
                .frame(width: 20)

                // Right side container - aligned to right edge
                HStack(spacing: VivaDesign.Spacing.small) {
                    Spacer(minLength: 0)  // Push content to right edge

                    let user = details.rightUsers.first
                    let invite = details.getInvites().first { invite in
                        invite.side == .right
                    }

                    VStack(alignment: .trailing) {
                        Text(getUserDisplayName(user: user, invite: invite))
                            .foregroundColor(VivaDesign.Colors.vivaGreen)
                            .font(VivaDesign.Typography.caption)
                            .lineLimit(1)
                        Text("\(details.rightSidePoints)")
                            .foregroundColor(VivaDesign.Colors.primaryText)
                            .font(VivaDesign.Typography.value)
                            .lineLimit(1)
                    }

                    VivaProfileImage(
                        userId: invite?.user?.id ?? user?.id,
                        imageUrl: invite?.user?.imageUrl ?? user?.imageUrl,
                        size: .small,
                        isInvited: invite != nil
                    )
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if details.status == .pending {
                if details.ownerId == userSession.userId {
                    Button(role: .destructive) {
                        Task {
                            _ = await viewModel.cancelMatchup()
                        }
                    } label: {
                        Text("Cancel")
                    }
                    .tint(VivaDesign.Colors.destructive)
                } else {
                    Button(role: .destructive) {
                        Task {
                            _ = await viewModel.removeCurrentUser(
                                userId: userSession.userId)
                        }
                    } label: {
                        Text("Leave")
                    }
                    .tint(VivaDesign.Colors.warning)
                }
            }
        }
    }

    private func getUserDisplayName(user: User?, invite: MatchupInvite?)
        -> String
    {
        if let invite = invite, let invitedUser = invite.user {
            return "\(invitedUser.displayName)"
        } else if let user = user {
            return user.displayName
        } else {
            return "Open"
        }
    }
}
