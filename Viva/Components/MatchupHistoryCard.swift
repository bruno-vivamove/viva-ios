//
//  MatchupCard.swift
//  Viva
//
//  Created by Bruno Souto on 1/9/25.
//

import SwiftUI

struct MatchupHistory {
    let opponent: User
    let record: String
}

struct MatchupHistoryCard: View {
    let history: MatchupHistory
    var body: some View {
        HStack(spacing: 0) {
            // Record column (left)
            Text(history.record)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)

            // VS column (center)
            Text("vs.")
                .font(.body)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)

            // Opponent info column (right)
            VStack(alignment: .center, spacing: 8) {
                Text(history.opponent.name)
                    .font(.body)
                    .foregroundColor(.vivaGreen)
                    .lineLimit(1)

                Image(history.opponent.imageURL)
                    .resizable()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
