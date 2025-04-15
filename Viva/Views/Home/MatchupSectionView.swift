import SwiftUI

struct MatchupSectionView: View {
    let title: String
    let matchups: [Matchup]
    let lastRefreshTime: Date?
    let onMatchupSelected: (Matchup) -> Void
    
    let matchupService: MatchupService
    let healthKitDataManager: HealthKitDataManager
    let userSession: UserSession
    let userMeasurementService: UserMeasurementService
    
    private let rowInsets = EdgeInsets(
        top: 0,
        leading: 0,
        bottom: 0,
        trailing: 0
    )
    
    var body: some View {
        Section {
            ForEach(matchups) { matchup in
                MatchupCard(
                    matchupId: matchup.id,
                    matchupService: matchupService,
                    userMeasurementService: userMeasurementService,
                    healthKitDataManager: healthKitDataManager,
                    userSession: userSession,
                    lastRefreshTime: lastRefreshTime
                )
                .id(matchup.id)
                .onTapGesture {
                    onMatchupSelected(matchup)
                }
                .listRowSeparator(.hidden)
                .listRowInsets(rowInsets)
                .padding(.bottom, VivaDesign.Spacing.cardSpacing)
            }
        } header: {
            SectionHeaderView(title: title)
        }
    }
} 