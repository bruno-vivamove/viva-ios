import SwiftUI

struct TrophiesView: View {
    @EnvironmentObject var userSession: UserSession
    @EnvironmentObject var friendService: FriendService
    @EnvironmentObject var matchupService: MatchupService
    @EnvironmentObject var userService: UserService
    @EnvironmentObject var healthKitDataManager: HealthKitDataManager
    @EnvironmentObject var userMeasurementService: UserMeasurementService
    
    @StateObject private var viewModel: TrophiesViewModel
    @State private var showMatchupCreation = false

    // Default initializer for use with SwiftUI previews and testing
    init() {
        // Will be overridden in onAppear with the actual matchupService from EnvironmentObject
        self._viewModel = StateObject(wrappedValue: TrophiesViewModel())
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Stats
                if let userStats = viewModel.userStats {
                    TrophiesHeader(
                        totalMatchups: userStats.totalMatchups,
                        timeRange: "All-Time ▼",
                        wins: userStats.wins,
                        losses: userStats.losses
                    )
                } else {
                    TrophiesHeader(
                        totalMatchups: 0,
                        timeRange: "All-Time ▼",
                        wins: 0,
                        losses: 0
                    )
                }
                
                VivaDivider()
                    .padding(.horizontal, VivaDesign.Spacing.outerPadding)
                
                // Matchup History
                if viewModel.isLoading && viewModel.matchupStats.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.bottom, 80)
                } else if viewModel.matchupStats.isEmpty {
                    EmptyStateView(message: "No matchup history yet")
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: .infinity, alignment: .center)
                        .padding(.bottom, 80)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(viewModel.matchupStats.enumerated()), id: \.element.matchupHash) { index, stats in
                                VStack(spacing: 0) {
                                    MatchupStatsCard(stats: stats)
                                        .padding(.vertical, 0)
                                    
                                    if index < viewModel.matchupStats.count - 1 {
                                        VivaDivider()
                                            .padding(.vertical, 8)
                                    }
                                }
                                .padding(.horizontal, VivaDesign.Spacing.outerPadding)
                            }
                            
                            Spacer()
                                .frame(height: 80)
                        }
                    }
                    .refreshable {
                        await viewModel.loadMatchupStats(using: matchupService)
                    }
                }
                
                Spacer(minLength: 0)
                
                // Create New Matchup Button
                VStack {
                    CardButton(
                        title: "Create New Matchup",
                        color: VivaDesign.Colors.primaryText
                    ) {
                        showMatchupCreation = true
                    }
                    .padding(.horizontal, VivaDesign.Spacing.outerPadding)
                    .padding(.bottom, VivaDesign.Spacing.small)
                }
                .background(Color.black)
                .edgesIgnoringSafeArea(.bottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .sheet(isPresented: $showMatchupCreation) {
                MatchupCategoriesView(
                    matchupService: matchupService,
                    friendService: friendService,
                    userService: userService,
                    userSession: userSession,
                    showCreationFlow: $showMatchupCreation
                )
                .presentationBackground(.clear)
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error)
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadMatchupStats(using: matchupService)
                }
            }
        }
    }
}

struct TrophiesHeader: View {
    let totalMatchups: Int
    let timeRange: String
    let wins: Int
    let losses: Int
    
    var body: some View {
        VStack(spacing: VivaDesign.Spacing.large) {
            // Total Matchups and Time Range
            HStack {
                Spacer()
                Text("\(totalMatchups)")
                    .foregroundColor(VivaDesign.Colors.vivaGreen)
                    .font(VivaDesign.Typography.caption.bold()) +
                Text(" Total Matchups")
                    .foregroundColor(VivaDesign.Colors.primaryText)
                    .font(VivaDesign.Typography.caption.bold())
                
                Spacer()
                
                Text(timeRange)
                    .foregroundColor(VivaDesign.Colors.primaryText)
                    .font(VivaDesign.Typography.caption.bold())
                    .padding(.horizontal, VivaDesign.Spacing.small)
                    .padding(.vertical, VivaDesign.Spacing.xsmall)
                Spacer()
            }
            
            // Win/Loss Stats
            HStack(spacing: VivaDesign.Spacing.medium) {
                // Wins
                StatDisplay(
                    icon: "trophy.fill",
                    iconColor: .yellow,
                    value: wins,
                    label: "wins",
                    labelColor: VivaDesign.Colors.vivaGreen
                )
                
                // Losses
                StatDisplay(
                    icon: "minus.circle.fill",
                    iconColor: .red,
                    value: losses,
                    label: "losses",
                    labelColor: VivaDesign.Colors.secondaryText
                )
            }
        }
    }
}

struct StatDisplay: View {
    let icon: String
    let iconColor: Color
    let value: Int
    let label: String
    let labelColor: Color
    
    var body: some View {
        HStack(spacing: VivaDesign.Spacing.xsmall) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
            Text("\(value)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(VivaDesign.Colors.primaryText)
            Text(label)
                .font(VivaDesign.Typography.title3)
                .foregroundColor(labelColor)
        }
    }
}

struct MatchupStatsCard: View {
    let stats: MatchupStats
    
    var body: some View {
        HStack(spacing: 0) {
            // Record
            Text("\(stats.userTeamWins)-\(stats.opponentTeamWins)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(VivaDesign.Colors.primaryText)
                .frame(maxWidth: .infinity, alignment: .center)
            
            // VS
            Text("vs")
                .font(VivaDesign.Typography.body)
                .foregroundColor(VivaDesign.Colors.primaryText)
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Opponent Info
            VStack(alignment: .center, spacing: VivaDesign.Spacing.xsmall) {
                // If there are users on the opponent team, display the first one
                if let opponent = stats.opponentTeamUsers.first {
                    Text(opponent.displayName)
                        .font(VivaDesign.Typography.body)
                        .foregroundColor(VivaDesign.Colors.vivaGreen)
                        .lineLimit(1)
                    
                    VivaProfileImage(
                        userId: opponent.id,
                        imageUrl: opponent.imageUrl,
                        size: .medium
                    )
                } else {
                    Text(stats.displayName)
                        .font(VivaDesign.Typography.body)
                        .foregroundColor(VivaDesign.Colors.vivaGreen)
                        .lineLimit(1)
                    
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(VivaDesign.Colors.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

struct EmptyStateView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: VivaDesign.Spacing.medium) {
            Image(systemName: "trophy")
                .font(.system(size: 50))
                .foregroundColor(VivaDesign.Colors.secondaryText)
            
            Text(message)
                .font(VivaDesign.Typography.body)
                .foregroundColor(VivaDesign.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// ViewModel
final class TrophiesViewModel: ObservableObject {
    @Published var matchupStats: [MatchupStats] = []
    @Published var userStats: UserStats?
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    init() {}
    
    @MainActor
    func loadMatchupStats(using matchupService: MatchupService) async {
        isLoading = true
        error = nil
        
        do {
            let response = try await matchupService.getMatchupStats()
            userStats = response.userStats
            matchupStats = response.matchupStats
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
}
