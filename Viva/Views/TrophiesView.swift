import SwiftUI

struct MatchupHistory {
    let opponent: User
    let record: String
}

struct TrophiesView: View {
    private let totalMatchups = 46
    private let wins = 25
    private let losses = 21
    private let timeRange = "All-Time ▼"
    
    private let matchupHistory = [
        MatchupHistory(
            opponent: User(
                id: "2",
                displayName: "Chris Dolan",
                imageUrl: nil,
                friendStatus: .friend
            ),
            record: "11-9"
        ),
        MatchupHistory(
            opponent: User(
                id: "3",
                displayName: "Bruno Souto",
                imageUrl: nil,
                friendStatus: .friend
            ),
            record: "5-6"
        ),
        MatchupHistory(
            opponent: User(
                id: "4",
                displayName: "Judah Levine",
                imageUrl: nil,
                friendStatus: .friend
            ),
            record: "9-6"
        ),
        MatchupHistory(
            opponent: User(
                id: "5",
                displayName: "Chris Dolan",
                imageUrl: nil,
                friendStatus: .friend
            ),
            record: "11-9"
        ),
        MatchupHistory(
            opponent: User(
                id: "6",
                displayName: "Bruno Souto",
                imageUrl: nil,
                friendStatus: .friend
            ),
            record: "5-6"
        ),
        MatchupHistory(
            opponent: User(
                id: "7",
                displayName: "Judah Levine",
                imageUrl: nil,
                friendStatus: .friend
            ),
            record: "9-6"
        ),
        MatchupHistory(
            opponent: User(
                id: "8",
                displayName: "Chris Dolan",
                imageUrl: nil,
                friendStatus: .friend
            ),
            record: "11-9"
        ),
        MatchupHistory(
            opponent: User(
                id: "9",
                displayName: "Bruno Souto",
                imageUrl: nil,
                friendStatus: .friend
            ),
            record: "5-6"
        ),
        MatchupHistory(
            opponent: User(
                id: "10",
                displayName: "Judah Levine",
                imageUrl: nil,
                friendStatus: .friend
            ),
            record: "9-6"
        ),
    ]
    
    var body: some View {
        VStack(spacing: VivaDesign.Spacing.small) {
            // Header Stats
            TrophiesHeader(
                totalMatchups: totalMatchups,
                timeRange: timeRange,
                wins: wins,
                losses: losses
            )
            
            VivaDivider()
                .padding(.horizontal)
            
            // Matchup History
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(matchupHistory.enumerated()), id: \.element.opponent.id) { index, history in
                        HistoryCard(history: history)
                            .padding(.vertical, VivaDesign.Spacing.small)
                        
                        if index < matchupHistory.count - 1 {
                            VivaDivider()
                                .padding(.horizontal)
                        }
                    }
                }
            }
            
            // Create New Matchup Button
            CardButton(title: "Create New Matchup") {
                // Add action here
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VivaDesign.Colors.background)
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
        .padding(.horizontal)
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

struct HistoryCard: View {
    let history: MatchupHistory
    
    var body: some View {
        HStack(spacing: 0) {
            // Record
            Text(history.record)
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
                Text(history.opponent.displayName)
                    .font(VivaDesign.Typography.body)
                    .foregroundColor(VivaDesign.Colors.vivaGreen)
                    .lineLimit(1)
                
                VivaProfileImage(
                    imageUrl: history.opponent.imageUrl,
                    size: .medium
                )
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

#Preview {
    TrophiesView()
}
