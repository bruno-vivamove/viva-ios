import Charts
import SwiftUI

struct WorkoutEntry: Identifiable {
    let id = UUID()
    let user: String
    let type: String
    let calories: Int
}

struct DailyActivity: Identifiable {
    let id = UUID()
    let day: String
    let value: Int
    let total: Int
}

struct MatchupDetailView: View {
    @StateObject private var viewModel: MatchupDetailViewModel
    @State private var isShowingTotal = true

    init(matchupService: MatchupService, matchupId: String) {
        _viewModel = StateObject(
            wrappedValue: MatchupDetailViewModel(
                matchupService: matchupService,
                matchupId: matchupId
            ))
    }

    var body: some View {
         Group {
             if viewModel.isLoading {
                 ProgressView()
                     .frame(maxWidth: .infinity, maxHeight: .infinity)
             } else if let matchup = viewModel.matchup {
                 VStack(spacing: VivaDesign.Spacing.medium) {
                     MatchupHeader(viewModel: viewModel)
                     .padding(.horizontal)

                     ViewToggle(isShowingTotal: $isShowingTotal)
                     
                     let totalMatchupMeasurementPairs = isShowingTotal ? viewModel.totalMatchupMeasurementPairs : viewModel.matchupMeasurementPairsByDay?.last
                     
                     VStack(spacing: VivaDesign.Spacing.medium) {
                         ForEach(Array(totalMatchupMeasurementPairs ?? [:]), id: \.key) { type, measurementPair in
                             ComparisonRow(
                                 leftValue: viewModel.formatValue(measurementPair.leftValue, for: type),
                                 leftPoints: "\(measurementPair.leftPoints) pts",
                                 title: viewModel.displayName(for: type),
                                 rightValue: viewModel.formatValue(measurementPair.rightValue, for: type),
                                 rightPoints: "\(measurementPair.rightPoints) pts"
                             )
                         }                     }
                     .padding(.horizontal, VivaDesign.Spacing.xlarge)

                     Spacer()

                     WorkoutsSection(workouts: [])
                         .padding(.horizontal, VivaDesign.Spacing.xlarge)

                     MatchupFooter(
                         endTime: matchup.endTime,
                         leftUser: matchup.leftUsers.first,
                         rightUser: matchup.rightUsers.first,
                         record: (wins: 11, losses: 9)
                     )
                     .padding(.horizontal)
                 }
                 .padding(.vertical, VivaDesign.Spacing.medium)
             }
         }
         .background(VivaDesign.Colors.background)
         .task {
             await viewModel.loadData()
         }
         .alert("Error", isPresented: .constant(viewModel.error != nil)) {
             Button("OK") {
                 viewModel.error = nil
             }
         } message: {
             if let error = viewModel.error {
                 Text(error.localizedDescription)
                     .lineLimit(1)
                     .truncationMode(.tail)
             }
         }
     }
}

#Preview {
    let userSession = VivaAppObjects.dummyUserSession()
    let vivaAppObjects = VivaAppObjects(userSession: userSession)

    MatchupDetailView(
        matchupService: vivaAppObjects.matchupService, matchupId: "abc123")
}

struct MatchupHeader: View {
    let viewModel: MatchupDetailViewModel

    var body: some View {
        HStack {
            UserScoreView(
                matchupUser: viewModel.matchup?.leftUsers.first,
                totalPoints: viewModel.totalPointsLeft ?? 0,
                imageOnLeft: true)
            Spacer()
            UserScoreView(
                matchupUser: viewModel.matchup?.rightUsers.first,
                totalPoints: viewModel.totalPointsRight ?? 0,
                imageOnLeft: false)
        }
    }
}

struct UserScoreView: View {
    let matchupUser: User?
    let totalPoints: Int
    let imageOnLeft: Bool

    var body: some View {
        HStack(spacing: 12) {
            if imageOnLeft {
                userImage
                userInfo
            } else {
                userInfo
                userImage
            }
        }
    }

    private var userImage: some View {
        VivaProfileImage(imageUrl: matchupUser?.imageUrl, size: .medium)
    }

    private var userInfo: some View {
        LabeledValueStack(
            label: matchupUser?.displayName ?? "Open Position",
            value: "\(totalPoints)",
            alignment: imageOnLeft ? .leading : .trailing)
            .lineLimit(1)
            .truncationMode(.tail)
    }
}

struct ViewToggle: View {
    @Binding var isShowingTotal: Bool

    var body: some View {
        HStack(spacing: VivaDesign.Spacing.minimal) {
            Text("Total")
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundColor(isShowingTotal ? VivaDesign.Colors.primaryText : VivaDesign.Colors.secondaryText)
            Text("|")
                .foregroundColor(VivaDesign.Colors.vivaGreen)
            Text("Today")
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundColor(isShowingTotal ? VivaDesign.Colors.secondaryText : VivaDesign.Colors.primaryText)
        }
        .onTapGesture {
            withAnimation {
                isShowingTotal.toggle()
            }
        }
    }
}

struct ComparisonRow: View {
    let leftValue: String
    let leftPoints: String
    let title: String
    let rightValue: String
    let rightPoints: String

    var body: some View {
        VStack {
            HStack {
                // Left side with fixed width
                VStack(alignment: .leading) {
                    Text(leftValue)
                        .font(.title2)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundColor(VivaDesign.Colors.primaryText)
                    Text(leftPoints)
                        .font(VivaDesign.Typography.caption)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundColor(VivaDesign.Colors.secondaryText)
                }
                .frame(width: 80, alignment: .leading) // Fixed width

                Spacer()

                // Center text with fixed position
                Text(title)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .font(.title2)
                    .foregroundColor(VivaDesign.Colors.vivaGreen)
                    .frame(width: 140, alignment: .center) // Fixed width

                Spacer()

                // Right side with fixed width
                VStack(alignment: .trailing) {
                    Text(rightValue)
                        .font(.title2)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundColor(VivaDesign.Colors.primaryText)
                    Text(rightPoints)
                        .font(VivaDesign.Typography.caption)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundColor(VivaDesign.Colors.secondaryText)
                }
                .frame(width: 80, alignment: .trailing) // Fixed width
            }

            VivaDivider()
        }
    }
}

struct WorkoutsSection: View {
    let workouts: [WorkoutEntry]

    var body: some View {
        VStack(spacing: VivaDesign.Spacing.small) {
            Text("Workouts")
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundColor(VivaDesign.Colors.primaryText)
                .frame(maxWidth: .infinity, alignment: .center)

            VivaDivider()

            ForEach(workouts) { workout in
                Text("\(workout.user) - \(workout.type) - \(workout.calories) Cals")
                    .font(VivaDesign.Typography.caption)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(VivaDesign.Colors.primaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}

struct MatchupFooter: View {
    let endTime: Date?
    let leftUser: User?
    let rightUser: User?
    let record: (wins: Int, losses: Int)

    var body: some View {
        HStack() {
            // Left section
            VStack(spacing: VivaDesign.Spacing.small) {
                Spacer()
                Text("Matchup Ends")
                    .font(VivaDesign.Typography.caption)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(VivaDesign.Colors.primaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                TimeRemainingDisplay(endTime: endTime)
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
            
            // Right section
            VStack(spacing: VivaDesign.Spacing.small) {
                Spacer()
                Text("All-Time Wins")
                    .font(VivaDesign.Typography.caption)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(VivaDesign.Colors.primaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                RecordDisplay(
                    leftUser: leftUser,
                    rightUser: rightUser,
                    wins: record.wins,
                    losses: record.losses
                )
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct TimeRemainingDisplay: View {
    let endTime: Date?

    var body: some View {
        if endTime == nil {
            HStack(spacing: VivaDesign.Spacing.minimal) {
                Text("Not started")
                    .font(.title)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .foregroundColor(VivaDesign.Colors.primaryText)
        } else {
            let remainingTime = calculateTimeRemaining()
            HStack(spacing: VivaDesign.Spacing.minimal) {
                Text("\(remainingTime.days)")
                    .font(.title)
                    .lineLimit(1)
                Text("d")
                    .foregroundColor(VivaDesign.Colors.vivaGreen)
                    .lineLimit(1)
                Text("\(remainingTime.hours)")
                    .font(.title)
                    .lineLimit(1)
                Text("hr")
                    .foregroundColor(VivaDesign.Colors.vivaGreen)
                    .lineLimit(1)
                Text("\(remainingTime.minutes)")
                    .font(.title)
                    .lineLimit(1)
                Text("min")
                    .foregroundColor(VivaDesign.Colors.vivaGreen)
                    .lineLimit(1)
            }
            .foregroundColor(VivaDesign.Colors.primaryText)
        }
    }

    private func calculateTimeRemaining() -> (
        days: Int, hours: Int, minutes: Int
    ) {
        let currentTime = Date()
        let timeInterval = max(endTime!.timeIntervalSince(currentTime), 0)

        let days = Int(timeInterval) / (24 * 60 * 60)
        let hours = (Int(timeInterval) % (24 * 60 * 60)) / (60 * 60)
        let minutes = (Int(timeInterval) % (60 * 60)) / 60

        return (days, hours, minutes)
    }
}

struct RecordDisplay: View {
    let leftUser: User?
    let rightUser: User?
    let wins: Int
    let losses: Int

    var body: some View {
        HStack(spacing: VivaDesign.Spacing.minimal) {
            VivaProfileImage(imageUrl: leftUser?.imageUrl, size: .mini)
            Text("\(wins)")
                .font(.title)
                .lineLimit(1)
            Spacer().frame(width: 10)
            Text("\(losses)")
                .font(.title)
                .lineLimit(1)
            VivaProfileImage(imageUrl: rightUser?.imageUrl, size: .mini)
        }
        .foregroundColor(VivaDesign.Colors.primaryText)
    }
}
