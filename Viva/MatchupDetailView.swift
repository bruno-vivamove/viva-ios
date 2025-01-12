//
//  MatchupDetail.swift
//  Viva
//
//  Created by Bruno Souto on 1/12/25.
//

//
//  MatchupDetailView.swift
//  Viva
//
//  Created by Bruno Souto on 1/12/25.
//

import Charts
import SwiftUI

struct WorkoutEntry {
    let user: String
    let type: String
    let calories: Int
}

struct DailyActivity {
    let day: String
    let value: Int
    let total: Int
}

struct MatchupDetailView: View {
    private let leftUser = User(
        id: "1",
        name: "Saya Jones",
        score: 1275,
        imageURL: "profile_stock"
    )

    private let rightUser = User(
        id: "4",
        name: "Judah Levine",
        score: 1113,
        imageURL: "profile_judah"
    )

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
        VStack(spacing: 24) {
            // Header with user info
            HStack {
                UserScoreView(user: leftUser, imageOnLeft: true)
                Spacer()
                UserScoreView(user: rightUser, imageOnLeft: false)
            }
            .padding(.horizontal)

            // View toggle
            HStack(spacing: 8) {
                Text("Today")
                    .foregroundColor(isShowingTotal ? .gray : .white)
                Text("|")
                    .foregroundColor(.vivaGreen)
                Text("Total")
                    .foregroundColor(isShowingTotal ? .white : .gray)
            }
            .onTapGesture {
                withAnimation {
                    isShowingTotal.toggle()
                }
            }

            // Stats Comparison
            VStack(spacing: 20) {
                StatComparisonRow(
                    leftValue: "1,023",
                    leftPoints: "274 pts",
                    title: "Active Cal",
                    rightValue: "989",
                    rightPoints: "264 pts"
                )

                StatComparisonRow(
                    leftValue: "12,345",
                    leftPoints: "257 pts",
                    title: "Steps",
                    rightValue: "11,113",
                    rightPoints: "386 pts"
                )

                StatComparisonRow(
                    leftValue: "65:18",
                    leftPoints: "265 pts",
                    title: "eHR Mins",
                    rightValue: "59:21",
                    rightPoints: "294 pts"
                )

                StatComparisonRow(
                    leftValue: "1:21:06",
                    leftPoints: "302 pts",
                    title: "Strength Train Mins",
                    rightValue: "1:06:07",
                    rightPoints: "280 pts"
                )

                StatComparisonRow(
                    leftValue: "7h 43m",
                    leftPoints: "257 pts",
                    title: "Sleep Mins",
                    rightValue: "7h 21m",
                    rightPoints: "280 pts"
                )
            }
            .padding(.horizontal)
            Spacer()

            // Activity Chart
            //                Chart {
            //                    ForEach(dailyActivities, id: \.day) { activity in
            //                        BarMark(
            //                            x: .value("Day", activity.day),
            //                            y: .value("Value", activity.value)
            //                        )
            //                        .foregroundStyle(Color.vivaGreen)
            //                    }
            //                }
            //                .frame(height: 200)
            //                .padding(.horizontal)

            // Workouts Section
            VStack(spacing: 12) {
                Text("Workouts")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .center)

                Rectangle()
                    .fill(Color.white.opacity(0.6))
                    .frame(height: 1.5)

                ForEach(workouts, id: \.type) { workout in
                    Text(
                        "\(workout.user) - \(workout.type) - \(workout.calories) Cals"
                    )
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.horizontal)

            // Footer Stats
            HStack {
                // Time remaining
                HStack(spacing: 4) {
                    Text("1")
                        .font(.title)
                    Text("d").foregroundColor(.vivaGreen)
                    Text("11")
                        .font(.title)
                    Text("hr").foregroundColor(.vivaGreen)
                    Text("43")
                        .font(.title)
                    Text("min").foregroundColor(.vivaGreen)
                }
                .foregroundColor(.white)

                Spacer()

                // Win/Loss record
                HStack(spacing: 8) {
                    Image(leftUser.imageURL)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                    Text("11")
                        .font(.title)
                    Spacer().frame(width: 10)
                    Text("9")
                        .font(.title)
                    Image(rightUser.imageURL)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                }
                .foregroundColor(.white)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color.black)
    }
}

// Supporting Views
struct UserScoreView: View {
    let user: User
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
        Image(user.imageURL)
            .resizable()
            .frame(width: 60, height: 60)
            .clipShape(Circle())
    }
    
    private var userInfo: some View {
        VStack(alignment: imageOnLeft ? .leading : .trailing) {
            Text(user.name)
                .foregroundColor(.vivaGreen)
            Text("\(user.score)")
                .font(.title2)
                .foregroundColor(.white)
        }
    }
}

struct StatComparisonRow: View {
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
                        .font(.title)
                        .foregroundColor(.white)
                    Text(leftPoints)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                Text(title)
                    .foregroundColor(.vivaGreen)

                Spacer()

                VStack(alignment: .trailing) {
                    Text(rightValue)
                        .font(.title)
                        .foregroundColor(.white)
                    Text(rightPoints)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Rectangle()
                .fill(Color.white.opacity(0.6))
                .frame(height: 1.5)
                .padding(0)
        }
    }
}

#Preview {
    MatchupDetailView()
}
