//
//  TrophiesView.swift
//  Viva
//
//  Created by Bruno Souto on 1/12/25.
//

import SwiftUI

struct TrophiesView: View {
    // Sample data that matches the screenshot
    private let totalMatchups = 46
    private let wins = 25
    private let losses = 21
    private let timeRange = "All-Time ▼"

    private let matchupHistory = [
        MatchupHistory(
            opponent: User(
                id: "2",
                name: "Chris Dolan",
                score: 1287,
                imageURL: "profile_chris"
            ),
            record: "11-9"
        ),
        MatchupHistory(
            opponent: User(
                id: "3",
                name: "Bruno Souto",
                score: 1168,
                imageURL: "profile_bruno"
            ),
            record: "5-6"
        ),
        MatchupHistory(
            opponent: User(
                id: "4",
                name: "Judah Levine",
                score: 1113,
                imageURL: "profile_judah"
            ),
            record: "9-6"
        ),
    ]

    var body: some View {
        VStack(spacing: 10) {
            // Header stats
            VStack(spacing: 40) {
                HStack {
                    Spacer()
                    Text("\(totalMatchups)")
                        .foregroundColor(.vivaGreen)
                        .font(.subheadline)
                        .fontWeight(.bold) +
                    Text(" Total Matchups")
                        .foregroundColor(.white)
                        .font(.subheadline)
                        .fontWeight(.bold)

                    Spacer()

                    Text(timeRange)
                        .foregroundColor(.white)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                    Spacer()
                }

                HStack(spacing: 24) {
                    // Wins
                    HStack(spacing: 8) {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.yellow)
                        Text("\(wins)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("wins")
                            .font(.title3)
                            .foregroundColor(.vivaGreen)
                    }

                    // Losses
                    HStack(spacing: 8) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                        Text("\(losses)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("losses")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal)

            Rectangle()
                .fill(Color.white.opacity(0.6))
                .frame(height: 1.5)
                .padding(.horizontal)

            // Matchup history
            VStack(spacing: 0) {
                ForEach(
                    Array(matchupHistory.enumerated()),
                    id: \.element.opponent.id
                ) { index, history in
                    MatchupHistoryCard(history: history)
                        .padding(.vertical, 10)

                    if index < matchupHistory.count - 1 {
                        Rectangle()
                            .fill(Color.white.opacity(0.6))
                            .frame(height: 1.5)
                            .padding(.horizontal)
                    }
                }
            }
            Spacer()

            // Create New Matchup Button
            Button(action: {
                // Add action here
            }) {
                Text("Create New Matchup")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.vivaGreen, lineWidth: 1)
                    )
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

#Preview {
    TrophiesView()
}
