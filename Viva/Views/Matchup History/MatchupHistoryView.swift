import Combine
import SwiftUI

struct MatchupHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userSession: UserSession
    @EnvironmentObject var friendService: FriendService
    @EnvironmentObject var matchupService: MatchupService
    @EnvironmentObject var userService: UserService
    @EnvironmentObject var healthKitDataManager: HealthKitDataManager
    @EnvironmentObject var userMeasurementService: UserMeasurementService

    @StateObject private var viewModel: MatchupHistoryViewModel
    @State private var showTimeFilter = false

    // Default initializer for use with SwiftUI previews and testing
    init(viewModel: MatchupHistoryViewModel) {
        // Will be overridden in onAppear with the actual matchupService from EnvironmentObject
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Pinned Header with Total Matchups
                MatchupHistoryHeaderBar(
                    userStats: viewModel.userStats,
                    showTimeFilter: $showTimeFilter
                )
                .padding(.horizontal, VivaDesign.Spacing.outerPadding)
                .padding(.vertical, VivaDesign.Spacing.small)

                // Matchup History
                if viewModel.isLoading && viewModel.matchupStats.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.bottom, 80)
                } else if viewModel.matchupStats.isEmpty
                    && viewModel.completedMatchups.isEmpty
                {
                    List {
                        EmptyStateSection(message: "No matchup history yet")
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: .infinity)
                            .frame(minHeight: UIScreen.main.bounds.height - 200)
                            .listRowBackground(Color.black)
                            .listRowInsets(EdgeInsets())
                    }
                    .listStyle(PlainListStyle())
                    .padding(.horizontal, VivaDesign.Spacing.outerPadding)
                    .listRowSpacing(0)
                    .background(Color.black)
                    .scrollContentBackground(.hidden)
                    .environment(\.defaultMinListRowHeight, 0)
                    .refreshable {
                        await viewModel.loadMatchupStats()
                    }
                } else {
                    // Stats and completed matchups in list
                    List {
                        // Stats section
                        if !viewModel.matchupStats.isEmpty {
                            MatchupStatsSection(
                                userStats: viewModel.userStats,
                                matchupStats: viewModel.matchupStats,
                                viewModel: viewModel
                            )
                        }

                        // Completed Matchups Section
                        if !viewModel.completedMatchups.isEmpty {
                            MatchupHistoryCompletedMatchupsSection(
                                viewModel: viewModel,
                                matchupService: matchupService,
                                healthKitDataManager: healthKitDataManager,
                                userSession: userSession,
                                userMeasurementService: userMeasurementService
                            )
                        }
                    }
                    .listStyle(PlainListStyle())
                    .padding(.horizontal, VivaDesign.Spacing.outerPadding)
                    .listRowSpacing(0)
                    .background(Color.black)
                    .scrollContentBackground(.hidden)
                    .environment(\.defaultMinListRowHeight, 0)
                    .refreshable {
                        await viewModel.loadMatchupStats()
                    }
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .sheet(isPresented: $showTimeFilter) {
                MatchupHistoryTimeFilterView(isPresented: $showTimeFilter)
                    .presentationDetents([.height(250)])
                    .presentationBackground(.clear)
            }
            .navigationDestination(item: $viewModel.selectedMatchup) {
                matchup in
                MatchupDetailView(
                    viewModel: MatchupDetailViewModel(
                        matchupId: matchup.id,
                        matchupService: matchupService,
                        userMeasurementService: userMeasurementService,
                        friendService: friendService,
                        userService: userService,
                        userSession: userSession,
                        healthKitDataManager: healthKitDataManager,
                    ),
                    source: "history"
                )
            }
            .navigationDestination(item: $viewModel.selectedUserId) { userId in
                ProfileView(
                    viewModel: ProfileViewModel(
                        userId: userId,
                        userSession: userSession,
                        userService: userService,
                        matchupService: matchupService
                    )
                )
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    if let vivaError = error as? VivaErrorResponse {
                        Text(vivaError.message)
                    } else {
                        Text(error.localizedDescription)
                    }
                }
            }
            .task {
                await viewModel.loadInitialDataIfNeeded()
            }
            .onChange(of: viewModel.selectedMatchup) { oldValue, newValue in
                if oldValue != nil && newValue == nil {
                    dismiss()
                }
            }
        }
    }
}

struct MatchupHistoryHeaderBar: View {
    let userStats: UserStats?
    @Binding var showTimeFilter: Bool

    var body: some View {
        HStack {
            if let userStats = userStats {
                Text("\(userStats.totalMatchups) Total Matchups")
                    .foregroundColor(VivaDesign.Colors.primaryText)
                    .font(VivaDesign.Typography.caption.bold())
            } else {
                Text("0 Total Matchups")
                    .foregroundColor(VivaDesign.Colors.primaryText)
                    .font(VivaDesign.Typography.caption.bold())
            }

            Spacer()

            Button(action: {
                showTimeFilter = true
            }) {
                Text("All-Time ▼")
                    .foregroundColor(VivaDesign.Colors.primaryText)
                    .font(VivaDesign.Typography.caption.bold())
                    .padding(.horizontal, VivaDesign.Spacing.small)
                    .padding(.vertical, VivaDesign.Spacing.xsmall)
            }
        }
    }
}

// MARK: - Stats Table Header
struct MatchupStatsTableHeader: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("W-L")
                    .font(VivaDesign.Typography.body)
                    .foregroundColor(
                        VivaDesign.Colors.primaryText
                    )
                    .frame(width: 60, alignment: .leading)

                Spacer()
                    .frame(width: VivaDesign.Spacing.medium)

                Text("")  // vs placeholder
                    .frame(width: 30)

                Spacer()
                    .frame(width: VivaDesign.Spacing.medium)

                Text("")  // image placeholder
                    .frame(width: 60)

                Spacer()
                    .frame(width: VivaDesign.Spacing.small)

                Spacer()
            }
        }
    }
}

// MARK: - Stats Section
struct MatchupStatsSection: View {
    let userStats: UserStats?
    let matchupStats: [MatchupStats]
    @ObservedObject var viewModel: MatchupHistoryViewModel

    var body: some View {
        // Header Stats Section
        Section {
            // Using the trophy header as a section header
            if let userStats = userStats {
                HStack(spacing: VivaDesign.Spacing.medium) {
                    VivaDivider()

                    // Total Score
                    Text("\(userStats.wins)-\(userStats.losses)")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(VivaDesign.Colors.primaryText)

                    VivaDivider()
                }
                .background(Color.black)
                .listRowBackground(Color.black)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }
        }

        // Matchups Section
        Section {
            // Table Header
            MatchupStatsTableHeader()
                .listRowBackground(Color.black)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .padding(.leading, VivaDesign.Spacing.xlarge)
                .padding(.bottom, VivaDesign.Spacing.small)

            VivaDivider()
                .listRowBackground(Color.black)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)


            // Matchup rows
            ForEach(matchupStats, id: \.matchupHash) { stats in
                VStack(spacing: 0) {
                    MatchupStatsCard(stats: stats, viewModel: viewModel)
                        .padding(.leading, VivaDesign.Spacing.xlarge)
                        .padding(.vertical, VivaDesign.Spacing.small)
                    VivaDivider()
                }
                .listRowBackground(Color.black)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }
        }
    }
}

// MARK: - Completed Matchups Section
struct MatchupHistoryCompletedMatchupsSection: View {
    @ObservedObject var viewModel: MatchupHistoryViewModel
    let matchupService: MatchupService
    let healthKitDataManager: HealthKitDataManager
    let userSession: UserSession
    let userMeasurementService: UserMeasurementService

    var body: some View {
        Section {
            ForEach(viewModel.completedMatchups) { matchup in
                MatchupCard(
                    matchupId: matchup.id,
                    matchupService: matchupService,
                    userMeasurementService: userMeasurementService,
                    healthKitDataManager: healthKitDataManager,
                    userSession: userSession,
                    lastRefreshTime: Date()
                )
                .id(matchup.id)
                .onTapGesture {
                    viewModel.selectedMatchup = matchup
                }
                .listRowBackground(Color.black)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
                .padding(.bottom, VivaDesign.Spacing.cardSpacing)
            }
        } header: {
            SectionHeaderView(title: "Matchup History")
        }
    }
}

struct MatchupStatsCard: View {
    let stats: MatchupStats
    @ObservedObject var viewModel: MatchupHistoryViewModel

    var body: some View {
        HStack(spacing: 0) {
            // User Record (11-9)
            Text("\(stats.userTeamWins)-\(stats.opponentTeamWins)")
                .font(VivaDesign.Typography.body.bold())
                .foregroundColor(VivaDesign.Colors.primaryText)
                .frame(width: 60, alignment: .leading)

            Spacer()
                .frame(width: VivaDesign.Spacing.xsmall)

            // VS - fixed position
            Text("vs.")
                .font(VivaDesign.Typography.body)
                .foregroundColor(VivaDesign.Colors.primaryText)
                .frame(width: 30, alignment: .center)

            Spacer()
                .frame(width: VivaDesign.Spacing.xsmall)

            // Opponent Info with Profile Picture - fixed position
            if let opponent = stats.opponentTeamUsers.first {
                VivaProfileImage(
                    userId: opponent.id,
                    imageUrl: opponent.imageUrl,
                    size: .mini
                )
                .frame(width: 60, alignment: .trailing)
                .onTapGesture {
                    viewModel.selectedUserId = opponent.id
                }

                Spacer()
                    .frame(width: VivaDesign.Spacing.small)

                Text(opponent.displayName)
                    .font(VivaDesign.Typography.body)
                    .foregroundColor(VivaDesign.Colors.primaryText)
                    .lineLimit(1)
                    .frame(alignment: .leading)
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(VivaDesign.Colors.secondaryText)
                    .frame(width: 60, alignment: .trailing)

                Spacer()
                    .frame(width: VivaDesign.Spacing.small)

                Text(stats.displayName)
                    .font(VivaDesign.Typography.body)
                    .foregroundColor(VivaDesign.Colors.primaryText)
                    .lineLimit(1)
                    .frame(alignment: .leading)
            }

            Spacer()
        }
    }
}

struct MatchupHistoryEmptyStateView: View {
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

struct MatchupHistoryTimeFilterView: View {
    @Binding var isPresented: Bool

    let timeOptions = ["All-Time", "This Year", "This Month", "This Week"]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Select Time Range")
                    .font(VivaDesign.Typography.header)
                    .foregroundColor(VivaDesign.Colors.primaryText)

                Spacer()

                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(VivaDesign.Colors.primaryText)
                }
            }
            .padding(.horizontal, VivaDesign.Spacing.outerPadding)
            .padding(.top, VivaDesign.Spacing.medium)
            .padding(.bottom, VivaDesign.Spacing.medium)

            // Options
            VStack(spacing: 0) {
                ForEach(timeOptions, id: \.self) { option in
                    Button(action: {
                        // Handle selection
                        isPresented = false
                    }) {
                        HStack {
                            Text(option)
                                .font(VivaDesign.Typography.body)
                                .foregroundColor(VivaDesign.Colors.primaryText)

                            Spacer()

                            if option == "All-Time" {
                                Image(systemName: "checkmark")
                                    .foregroundColor(
                                        VivaDesign.Colors.vivaGreen
                                    )
                            }
                        }
                        .padding(.horizontal, VivaDesign.Spacing.outerPadding)
                        .padding(.vertical, VivaDesign.Spacing.small)
                    }

                    if option != timeOptions.last {
                        VivaDivider()
                            .padding(
                                .horizontal,
                                VivaDesign.Spacing.outerPadding
                            )
                    }
                }
            }

            Spacer()
        }
        .background(Color.black)
    }
}

// MARK: - Empty State Section
struct EmptyStateSection: View {
    let message: String

    var body: some View {
        VStack {
            MatchupHistoryEmptyStateView(message: message)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
