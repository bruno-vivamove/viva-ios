import SwiftUI

struct MatchupCard: View {
    @EnvironmentObject var userSession: UserSession
    @StateObject private var viewModel: MatchupCardViewModel

    // Add this property to trigger updates
    var lastRefreshTime: Date?

    init(
        matchupId: String,
        matchupService: MatchupService,
        userMeasurementService: UserMeasurementService,
        healthKitDataManager: HealthKitDataManager,
        userSession: UserSession,
        lastRefreshTime: Date? = nil
    ) {
        self.lastRefreshTime = lastRefreshTime
        _viewModel = StateObject(
            wrappedValue: MatchupCardViewModel(
                matchupId: matchupId,
                matchupService: matchupService,
                userMeasurementService: userMeasurementService,
                healthKitDataManager: healthKitDataManager,
                userSession: userSession,
                lastRefreshTime: lastRefreshTime
            ))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.matchupDetails == nil {
                skeletonLoadingView
            } else if let details = viewModel.matchupDetails {
                matchupCardView(details)
            } else {
                errorView
            }
        }
        .background(Color.black)
        .listRowBackground(Color.clear)
        .onChange(of: lastRefreshTime) { oldValue, newValue in
            viewModel.updateLastRefreshTime(newValue)
        }
    }

    private func matchupCardView(_ details: MatchupDetails) -> some View {
        VivaCard {
            HStack(spacing: 0) {
                // Left side container - aligned to left edge
                HStack(spacing: VivaDesign.Spacing.small) {
                    let leftTeam = details.leftTeam
                    let user = details.leftUsers.first
                    let invite = details.invites.first { invite in
                        invite.matchupTeamId == leftTeam?.id
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

                    let rightTeam = details.rightTeam
                    let user = details.rightUsers.first
                    let invite = details.invites.first { invite in
                        invite.matchupTeamId == rightTeam?.id
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
                        guard let userId = userSession.userId else {
                            return
                        }

                        Task {
                            _ = await viewModel.removeCurrentUser(
                                userId: userId)
                        }
                    } label: {
                        Text("Leave")
                    }
                    .tint(VivaDesign.Colors.warning)
                }
            }
        }
    }

    var skeletonLoadingView: some View {
        // Extract the placeholder color as a constant
        let placeholderColor = Color.gray.opacity(0.6)

        return VivaCard {
            HStack(spacing: 0) {
                // Left side container - aligned to left edge
                HStack(spacing: VivaDesign.Spacing.small) {
                    // Profile image placeholder
                    Circle()
                        .fill(placeholderColor)
                        .frame(
                            width: VivaDesign.Sizing.ProfileImage.small
                                .rawValue,
                            height: VivaDesign.Sizing.ProfileImage.small
                                .rawValue)

                    VStack(alignment: .leading) {
                        // Name placeholder
                        RoundedRectangle(cornerRadius: 2)
                            .fill(placeholderColor)
                            .frame(width: 80, height: 14)

                        // Points placeholder
                        RoundedRectangle(cornerRadius: 2)
                            .fill(placeholderColor)
                            .frame(width: 40, height: 18)
                    }

                    Spacer(minLength: 0)
                }

                // Centered divider with fixed width container
                HStack {
                    Text("|")
                        .foregroundColor(
                            VivaDesign.Colors.secondaryText.opacity(0.5)
                        )
                        .font(VivaDesign.Typography.title3)
                }
                .frame(width: 20)

                // Right side container - aligned to right edge
                HStack(spacing: VivaDesign.Spacing.small) {
                    Spacer(minLength: 0)

                    VStack(alignment: .trailing) {
                        // Name placeholder
                        RoundedRectangle(cornerRadius: 2)
                            .fill(placeholderColor)
                            .frame(width: 80, height: 14)

                        // Points placeholder
                        RoundedRectangle(cornerRadius: 2)
                            .fill(placeholderColor)
                            .frame(width: 40, height: 18)
                    }

                    // Profile image placeholder
                    Circle()
                        .fill(placeholderColor)
                        .frame(
                            width: VivaDesign.Sizing.ProfileImage.small
                                .rawValue,
                            height: VivaDesign.Sizing.ProfileImage.small
                                .rawValue)
                }
            }
            .shimmering(
                animation: VivaDesign.AnimationStyle.loadingShimmer)
        }
    }

    private var errorView: some View {
        VivaCard {
            HStack(spacing: 0) {
                // Left side container - aligned to left edge
                VivaProfileImage(
                    userId: nil,
                    imageUrl: nil,
                    size: .small,
                    isInvited: false
                )
                Spacer(minLength: 0)  // Push content to left edge

                // Centered divider with fixed width container
                Text("Error loading matchup")
                    .foregroundColor(VivaDesign.Colors.secondaryText)
                    .font(VivaDesign.Typography.caption)

                // Right side container - aligned to right edge
                Spacer(minLength: 0)  // Push content to right edge

                VivaProfileImage(
                    userId: nil,
                    imageUrl: nil,
                    size: .small,
                    isInvited: false
                )
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
