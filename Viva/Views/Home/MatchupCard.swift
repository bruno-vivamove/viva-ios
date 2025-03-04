import SwiftUI

struct MatchupCard: View {
    @EnvironmentObject var userSession: UserSession
    @StateObject private var viewModel: MatchupCardViewModel
    
    init(matchupId: String, matchupService: MatchupService) {
        _viewModel = StateObject(wrappedValue: MatchupCardViewModel(
            matchupId: matchupId,
            matchupService: matchupService
        ))
    }
    
    // This function allows parent views to refresh this card
    func refresh() async {
        await viewModel.refresh()
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
                    let leftInvite = details.invites.first { invite in
                        invite.side == .left
                    }

                    VivaProfileImage(
                        imageUrl: leftInvite?.user?.imageUrl ?? user?.imageUrl,
                        size: .small,
                        isInvited: leftInvite != nil
                    )

                    LabeledValueStack(
                        label: getUserDisplayName(
                            user: user, invite: leftInvite),
                        value: "\(details.leftSidePoints)",
                        alignment: .leading
                    )

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
                    let rightInvite = details.invites.first { invite in
                        invite.side == .right
                    }

                    LabeledValueStack(
                        label: getUserDisplayName(
                            user: user, invite: rightInvite),
                        value: "\(details.rightSidePoints)",
                        alignment: .trailing
                    )

                    VivaProfileImage(
                        imageUrl: rightInvite?.user?.imageUrl ?? user?.imageUrl,
                        size: .small,
                        isInvited: rightInvite != nil
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
                            _ = await viewModel.removeCurrentUser(userId: userSession.userId)
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
