//
//  HomeHeader.swift
//  Viva
//
//  Created by Bruno Souto on 1/12/25.
//
import SwiftUI

struct HomeHeader: View {
    var body: some View {
        GeometryReader { geometry in
            HStack {
                // Left side stats group
                HStack(spacing: min(16, geometry.size.width * 0.03)) {
                    // Streak View
                    VStack(alignment: .leading, spacing: 2) {
                        Text("17 wks")
                            .font(.title3)
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                        Text("Current Streak")
                            .font(.caption)
                            .foregroundColor(.vivaGreen)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .frame(maxWidth: geometry.size.width * 0.25)

                    // Points View
                    VStack(alignment: .leading, spacing: 2) {
                        Text("3,017")
                            .font(.title3)
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .frame(alignment: .center)
                        Text("Reward Points")
                            .font(.caption)
                            .foregroundColor(.vivaGreen)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .frame(maxWidth: geometry.size.width * 0.25)
                }

                Spacer(minLength: min(16, geometry.size.width * 0.02))

                // Create New Matchup Button
                Button(action: {
                    // Add action here
                }) {
                    Text("Create New Matchup")
                        .font(
                            .system(
                                size: min(15, geometry.size.width * 0.035))
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(
                            .horizontal, min(12, geometry.size.width * 0.03)
                        )
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.vivaGreen, lineWidth: 1)
                        )
                        .foregroundColor(.white)
                }
                .frame(maxWidth: geometry.size.width * 0.35)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, min(12, geometry.size.width * 0.03))
            .padding(.top, 8)
        }
        .frame(height: 60)
    }
}
