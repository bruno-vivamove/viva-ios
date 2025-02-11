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
    private let matchup = Matchup(
        id: "1", matchupHash: "hash", displayName: "Saya Jones", ownerId: "1",
        createTime: Date(),
        status: .pending,
        startTime: nil,
        endTime: nil,
        usersPerSide: 1,
        leftUsers: [User(id: "1", displayName: "Saya Jones", imageUrl: nil, friendStatus: .friend)],
        rightUsers: [User(id: "2", displayName: "Judah Levine", imageUrl: nil, friendStatus: .friend)])

    private let workouts = [
        WorkoutEntry(user: "Saya Jones", type: "Running", calories: 347),
        WorkoutEntry(user: "Judah Levine", type: "Yoga", calories: 425),
        WorkoutEntry(user: "Saya Jones", type: "HIIT", calories: 647),
    ]

    private let dailyActivities = [
        DailyActivity(day: "Fri", value: 183, total: 401),
        DailyActivity(day: "Sat", value: 439, total: 439),
        DailyActivity(day: "Sun", value: 268, total: 500),
        DailyActivity(day: "Mon", value: 312, total: 540),
        DailyActivity(day: "Tue", value: 183, total: 188),
        DailyActivity(day: "Wed", value: 0, total: 0),
        DailyActivity(day: "Thu", value: 0, total: 0),
    ]

    @State private var isShowingTotal = false

    var body: some View {
        VStack(spacing: VivaDesign.Spacing.medium) {
            // Header with user info
            MatchupHeader(
                leftUser: matchup.leftUsers[0], rightUser: matchup.rightUsers[0]
            )
            .padding(.horizontal)

            // View toggle
            ViewToggle(isShowingTotal: $isShowingTotal)

            // Stats Comparison
            VStack(spacing: VivaDesign.Spacing.medium) {
                ComparisonRow(
                    leftValue: "1,023",
                    leftPoints: "274 pts",
                    title: "Active Cal",
                    rightValue: "989",
                    rightPoints: "264 pts"
                )

                ComparisonRow(
                    leftValue: "12,345",
                    leftPoints: "257 pts",
                    title: "Steps",
                    rightValue: "11,113",
                    rightPoints: "386 pts"
                )

                ComparisonRow(
                    leftValue: "65:18",
                    leftPoints: "265 pts",
                    title: "eHR Mins",
                    rightValue: "59:21",
                    rightPoints: "294 pts"
                )

                ComparisonRow(
                    leftValue: "1:21:06",
                    leftPoints: "302 pts",
                    title: "Strength Train Mins",
                    rightValue: "1:06:07",
                    rightPoints: "280 pts"
                )

                ComparisonRow(
                    leftValue: "7h 43m",
                    leftPoints: "257 pts",
                    title: "Sleep Mins",
                    rightValue: "7h 21m",
                    rightPoints: "280 pts"
                )
            }
            .padding(.horizontal, VivaDesign.Spacing.xlarge)

            Spacer()

            // Workouts Section
            WorkoutsSection(workouts: workouts)
                .padding(.horizontal, VivaDesign.Spacing.xlarge)

            // Footer Stats
            MatchupFooter(
                endTime: matchup.endTime,
                leftUser: matchup.leftUsers[0],
                rightUser: matchup.rightUsers[0],
                record: (wins: 11, losses: 9)
            )
            .padding(.horizontal)
        }
        .padding(.vertical, VivaDesign.Spacing.medium)
        .background(VivaDesign.Colors.background)
    }
}

#Preview {
    MatchupDetailView()
}

struct MatchupHeader: View {
    let leftUser: User
    let rightUser: User

    var body: some View {
        HStack {
            UserScoreView(matchupUser: leftUser, imageOnLeft: true)
            Spacer()
            UserScoreView(matchupUser: rightUser, imageOnLeft: false)
        }
    }
}

struct UserScoreView: View {
    let matchupUser: User
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
        Image(systemName: "person.circle.fill")
            .resizable()
            .frame(width: 60, height: 60)
            .clipShape(Circle())
    }

    private var userInfo: some View {
        LabeledValueStack(
            label: matchupUser.displayName, value: "\(1000)",
            alignment: imageOnLeft ? .leading : .trailing)
    }
}

struct ViewToggle: View {
    @Binding var isShowingTotal: Bool

    var body: some View {
        HStack(spacing: VivaDesign.Spacing.minimal) {
            Text("Today")
                .foregroundColor(
                    isShowingTotal
                        ? VivaDesign.Colors.secondaryText
                        : VivaDesign.Colors.primaryText)
            Text("|")
                .foregroundColor(VivaDesign.Colors.vivaGreen)
            Text("Total")
                .foregroundColor(
                    isShowingTotal
                        ? VivaDesign.Colors.primaryText
                        : VivaDesign.Colors.secondaryText)
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
                VStack(alignment: .leading) {
                    Text(leftValue)
                        .font(.title2)
                        .foregroundColor(VivaDesign.Colors.primaryText)
                    Text(leftPoints)
                        .font(VivaDesign.Typography.caption)
                        .foregroundColor(VivaDesign.Colors.secondaryText)
                }

                Spacer()

                Text(title)
                    .foregroundColor(VivaDesign.Colors.vivaGreen)

                Spacer()

                VStack(alignment: .trailing) {
                    Text(rightValue)
                        .font(.title2)
                        .foregroundColor(VivaDesign.Colors.primaryText)
                    Text(rightPoints)
                        .font(VivaDesign.Typography.caption)
                        .foregroundColor(VivaDesign.Colors.secondaryText)
                }
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
                .foregroundColor(VivaDesign.Colors.primaryText)
                .frame(maxWidth: .infinity, alignment: .center)

            VivaDivider()

            ForEach(workouts) { workout in
                Text(
                    "\(workout.user) - \(workout.type) - \(workout.calories) Cals"
                )
                .font(VivaDesign.Typography.caption)
                .foregroundColor(VivaDesign.Colors.primaryText)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}

struct MatchupFooter: View {
    let endTime: Date?
    let leftUser: User
    let rightUser: User
    let record: (wins: Int, losses: Int)

    var body: some View {
        HStack {
            // Time remaining
            TimeRemainingDisplay(endTime: endTime)

            Spacer()

            // Win/Loss record
            RecordDisplay(
                leftUser: leftUser,
                rightUser: rightUser,
                wins: record.wins,
                losses: record.losses
            )
        }
    }
}

struct TimeRemainingDisplay: View {
    let endTime: Date?

    var body: some View {
        if(endTime == nil) {
            HStack(spacing: VivaDesign.Spacing.minimal) {
                Text("Not yest started")
                    .font(.title)
            }
        } else {
            let remainingTime = calculateTimeRemaining()
            HStack(spacing: VivaDesign.Spacing.minimal) {
                Text("\(remainingTime.days)")
                    .font(.title)
                Text("d").foregroundColor(VivaDesign.Colors.vivaGreen)
                Text("\(remainingTime.hours)")
                    .font(.title)
                Text("hr").foregroundColor(VivaDesign.Colors.vivaGreen)
                Text("\(remainingTime.minutes)")
                    .font(.title)
                Text("min").foregroundColor(VivaDesign.Colors.vivaGreen)
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
    let leftUser: User
    let rightUser: User
    let wins: Int
    let losses: Int

    var body: some View {
        HStack(spacing: VivaDesign.Spacing.minimal) {
            VivaProfileImage(imageUrl: leftUser.imageUrl, size: .mini)
            Text("\(wins)")
                .font(.title)
            Spacer().frame(width: 10)
            Text("\(losses)")
                .font(.title)
            VivaProfileImage(imageUrl: rightUser.imageUrl, size: .mini)
        }
        .foregroundColor(VivaDesign.Colors.primaryText)
    }
}
