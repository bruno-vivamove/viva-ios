import SkeletonView
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

    private var skeletonLoadingView: some View {
        VivaCard {
            HStack(spacing: 0) {
                // Left side container - aligned to left edge
                HStack(spacing: VivaDesign.Spacing.small) {
                    SkeletonProfileImageView(
                        size: VivaDesign.Sizing.ProfileImage.small.rawValue,
                        isInvited: false
                    )
                    .frame(
                        width: VivaDesign.Sizing.ProfileImage.small.rawValue,
                        height: VivaDesign.Sizing.ProfileImage.small.rawValue)

                    VStack(alignment: .leading) {
                        SkeletonTextView(width: 80, height: 14, fontSize: 12)
                            .frame(width: 80, height: 14)
                            .padding(.bottom, 4)
                        SkeletonTextView(width: 40, height: 20, fontSize: 16)
                            .frame(width: 40, height: 20)
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

                    VStack(alignment: .trailing) {
                        SkeletonTextView(
                            width: 80, height: 14, fontSize: 12,
                            alignment: .right
                        )
                        .frame(width: 80, height: 14)
                        .padding(.bottom, 4)
                        SkeletonTextView(
                            width: 40, height: 20, fontSize: 16,
                            alignment: .right
                        )
                        .frame(width: 40, height: 20)
                    }

                    SkeletonProfileImageView(
                        size: VivaDesign.Sizing.ProfileImage.small.rawValue,
                        isInvited: false
                    )
                    .frame(
                        width: VivaDesign.Sizing.ProfileImage.small.rawValue,
                        height: VivaDesign.Sizing.ProfileImage.small.rawValue)
                }
            }
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

// UIViewRepresentable wrapper for skeleton text using SkeletonView's built-in text support
struct SkeletonTextView: UIViewRepresentable {
    let width: CGFloat
    let height: CGFloat
    let fontSize: CGFloat
    let multiline: Bool
    let alignment: NSTextAlignment

    init(
        width: CGFloat,
        height: CGFloat,
        fontSize: CGFloat = 14,
        multiline: Bool = false,
        alignment: NSTextAlignment = .left
    ) {
        self.width = width
        self.height = height
        self.fontSize = fontSize
        self.multiline = multiline
        self.alignment = alignment
    }

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = multiline ? 0 : 1
        label.font = UIFont.systemFont(ofSize: fontSize)
        label.textColor = .white
        label.isSkeletonable = true
        label.linesCornerRadius = 4
        label.textAlignment = alignment  // This sets the alignment for the skeleton lines

        // Set specific width if needed
        if width > 0 {
            label.preferredMaxLayoutWidth = width
        }

        // Apply skeleton animation with gradient
        let gradient = SkeletonGradient(
            baseColor: UIColor(Color(red: 0.1, green: 0.1, blue: 0.1)),
            secondaryColor: UIColor.lightGray)
        let animation = SkeletonAnimationBuilder().makeSlidingAnimation(
            withDirection: .topLeftBottomRight)

        // This is key - SkeletonView has special handling for UILabels
        label.showAnimatedGradientSkeleton(
            usingGradient: gradient, animation: animation)

        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {
        // No updates needed
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize, uiView: UILabel, context: Context
    ) -> CGSize {
        return CGSize(width: width, height: height)
    }
}
