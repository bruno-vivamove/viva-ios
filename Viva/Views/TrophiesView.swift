import Combine
import SwiftUI

struct TrophiesView: View {
    @EnvironmentObject var userSession: UserSession
    @EnvironmentObject var friendService: FriendService
    @EnvironmentObject var matchupService: MatchupService
    @EnvironmentObject var userService: UserService
    @EnvironmentObject var healthKitDataManager: HealthKitDataManager
    @EnvironmentObject var userMeasurementService: UserMeasurementService

    @StateObject private var viewModel: TrophiesViewModel
    @State private var selectedMatchup: Matchup?
    @State private var showTimeFilter = false

    // Default initializer for use with SwiftUI previews and testing
    init() {
        // Will be overridden in onAppear with the actual matchupService from EnvironmentObject
        self._viewModel = StateObject(wrappedValue: TrophiesViewModel())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Pinned Header with Total Matchups
                TrophiesHeaderBar(
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
                    EmptyStateSection(message: "No matchup history yet")
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: .infinity, alignment: .center)
                        .padding(.bottom, 80)
                } else {
                    // Stats and completed matchups in list
                    List {
                        // Stats section
                        if !viewModel.matchupStats.isEmpty {
                            MatchupStatsSection(
                                userStats: viewModel.userStats,
                                matchupStats: viewModel.matchupStats
                            )
                        }

                        // Completed Matchups Section
                        if !viewModel.completedMatchups.isEmpty {
                            TrophyCompletedMatchupsSection(
                                matchups: viewModel.completedMatchups,
                                matchupService: matchupService,
                                healthKitDataManager: healthKitDataManager,
                                userSession: userSession,
                                userMeasurementService: userMeasurementService,
                                selectedMatchup: $selectedMatchup
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
                        await viewModel.loadMatchupStats(using: matchupService)
                    }
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .sheet(isPresented: $showTimeFilter) {
                TimeFilterView(isPresented: $showTimeFilter)
                    .presentationDetents([.height(250)])
                    .presentationBackground(.clear)
            }
            .navigationDestination(item: $selectedMatchup) { matchup in
                MatchupDetailView(
                    viewModel: MatchupDetailViewModel(
                        matchupId: matchup.id,
                        matchupService: matchupService,
                        userMeasurementService: userMeasurementService,
                        friendService: friendService,
                        userService: userService,
                        userSession: userSession,
                        healthKitDataManager: healthKitDataManager
                    )
                )
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
                    setupNotificationObservers()
                }
            }
        }
    }

    func setupNotificationObservers() {
        // Home screen matchup creation completed observer
        NotificationCenter.default.removeObserver(
            self,
            name: .homeScreenMatchupCreationCompleted,
            object: nil
        )
        NotificationCenter.default.addObserver(
            forName: .homeScreenMatchupCreationCompleted,
            object: nil,
            queue: .main
        ) { notification in
            guard let matchupDetails = notification.object as? MatchupDetails,
                let userInfo = notification.userInfo,
                let source = userInfo["source"] as? String,
                source == "trophies"
            else {
                return
            }

            selectedMatchup = matchupDetails.asMatchup
        }
    }
}

struct TrophiesHeaderBar: View {
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
                        VivaDesign.Colors.vivaGreen
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
            .padding(.leading, VivaDesign.Spacing.large)
            .padding(.bottom, VivaDesign.Spacing.small)

            VivaDivider()
        }
    }
}

// MARK: - Stats Section
struct MatchupStatsSection: View {
    let userStats: UserStats?
    let matchupStats: [MatchupStats]

    var body: some View {
        Section {
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

                // Matchup rows
                ForEach(matchupStats, id: \.matchupHash) { stats in
                    VStack(spacing: 0) {
                        MatchupStatsCard(stats: stats)
                            .padding(.leading, VivaDesign.Spacing.large)
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
}

// MARK: - Completed Matchups Section
struct TrophyCompletedMatchupsSection: View {
    let matchups: [Matchup]
    let matchupService: MatchupService
    let healthKitDataManager: HealthKitDataManager
    let userSession: UserSession
    let userMeasurementService: UserMeasurementService
    @Binding var selectedMatchup: Matchup?

    var body: some View {
        Section {
            ForEach(matchups) { matchup in
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
                    selectedMatchup = matchup
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

    var body: some View {
        HStack(spacing: 0) {
            // User Record (11-9)
            Text("\(stats.userTeamWins)-\(stats.opponentTeamWins)")
                .font(VivaDesign.Typography.body.bold())
                .foregroundColor(VivaDesign.Colors.primaryText)
                .frame(width: 60, alignment: .leading)

            Spacer()
                .frame(width: VivaDesign.Spacing.medium)

            // VS - fixed position
            Text("vs.")
                .font(VivaDesign.Typography.body)
                .foregroundColor(VivaDesign.Colors.primaryText)
                .frame(width: 30, alignment: .center)

            Spacer()
                .frame(width: VivaDesign.Spacing.medium)

            // Opponent Info with Profile Picture - fixed position
            if let opponent = stats.opponentTeamUsers.first {
                VivaProfileImage(
                    userId: opponent.id,
                    imageUrl: opponent.imageUrl,
                    size: .mini
                )
                .frame(width: 60, alignment: .trailing)

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

struct TimeFilterView: View {
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
        EmptyStateView(message: message)
    }
}

// ViewModel
final class TrophiesViewModel: ObservableObject {
    @Published var matchupStats: [MatchupStats] = []
    @Published var userStats: UserStats?
    @Published var completedMatchups: [Matchup] = []
    @Published var isLoading: Bool = false
    @Published var error: String?

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupNotificationObservers()
    }

    private func setupNotificationObservers() {
        // Matchup updated observer
        NotificationCenter.default.publisher(for: .matchupUpdated)
            .compactMap { $0.object as? MatchupDetails }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] matchupDetails in
                let updatedMatchup = matchupDetails.asMatchup

                // Update completed matchups if status changed to completed
                if updatedMatchup.status == .completed {
                    self?.handleMatchupStatusChanged(updatedMatchup)
                }
            }
            .store(in: &cancellables)

        // Matchup canceled observer
        NotificationCenter.default.publisher(for: .matchupCanceled)
            .compactMap { $0.object as? Matchup }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] matchup in
                self?.handleMatchupCanceled(matchup)
            }
            .store(in: &cancellables)
    }

    private func handleMatchupStatusChanged(_ updatedMatchup: Matchup) {
        // If the matchup status changed to completed, add it to completedMatchups
        if updatedMatchup.status == .completed {
            if !completedMatchups.contains(where: { $0.id == updatedMatchup.id }
            ) {
                completedMatchups.append(updatedMatchup)
            } else {
                // Update existing matchup
                if let index = completedMatchups.firstIndex(where: {
                    $0.id == updatedMatchup.id
                }) {
                    completedMatchups[index] = updatedMatchup
                }
            }

            // Also refresh stats since they may have changed
            Task {
                if let matchupService = matchupService {
                    do {
                        let response =
                            try await matchupService.getMatchupStats()
                        self.userStats = response.userStats
                        self.matchupStats = response.matchupStats
                    } catch {
                        // Ignore errors when refreshing in background
                    }
                }
            }
        }
    }

    private func handleMatchupCanceled(_ matchup: Matchup) {
        // Remove from completed matchups if it exists
        completedMatchups.removeAll { $0.id == matchup.id }
    }

    private var matchupService: MatchupService?

    @MainActor
    func loadMatchupStats(using matchupService: MatchupService) async {
        isLoading = true
        error = nil
        self.matchupService = matchupService

        do {
            // Load matchup stats and all matchups concurrently
            async let statsTask = matchupService.getMatchupStats()
            async let matchupsTask = matchupService.getMyMatchups(filter: .COMPLETED_ONLY)

            // Await all results
            let (statsResponse, matchupsResponse) = try await (
                statsTask, matchupsTask
            )

            // Update the published properties
            userStats = statsResponse.userStats
            matchupStats = statsResponse.matchupStats

            // Use the completed matchups from the response
            completedMatchups = matchupsResponse.matchups

            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
}
