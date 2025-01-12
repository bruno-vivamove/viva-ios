//
//  MatchupCard.swift
//  Viva
//
//  Created by Bruno Souto on 1/9/25.
//

import SwiftUI

struct MatchupCard: View {
    let matchup: Matchup
    
    var body: some View {
        HStack {
            // Left User
            HStack(spacing: 12) {
                Image("profile_stock")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    Text(matchup.leftUser.name)
                        .foregroundColor(.vivaGreen)
                        .font(.subheadline)
                    Text("\(matchup.leftUser.score)")
                        .foregroundColor(.white)
                        .font(.title3)
                }
            }
            
            Spacer()
            
            // Divider
            Text("/")
                .foregroundColor(.gray)
                .font(.title3)
            
            Spacer()
            
            // Right User
            HStack(spacing: 12) {
                VStack(alignment: .trailing) {
                    Text(matchup.rightUser.name)
                        .foregroundColor(.vivaGreen)
                        .font(.subheadline)
                    Text("\(matchup.rightUser.score)")
                        .foregroundColor(.white)
                        .font(.title3)
                }
                
                Image("profile_judah")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                )
        )
    }
}
