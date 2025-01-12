//
//  HomeView.swift
//  Viva
//
//  Created by Bruno Souto on 1/9/25.
//

import SwiftUI

struct Matchup {
    let leftUser: User
    let rightUser: User
    let timeLeft: String
}

struct PendingInvitation {
    let user: User
    let type: InvitationType
}

enum InvitationType {
    case accept
    case remind
}

struct HomeView: View {
    // Add sample data
    private let liveMatchups = [
        Matchup(
            leftUser: User(
                id: "1", name: "Saya Jones", score: 1275,
                imageURL: "saya_profile"),
            rightUser: User(
                id: "2", name: "Chris Dolan", score: 1287,
                imageURL: "chris_profile"),
            timeLeft: "1d 11h left"
        ),
        Matchup(
            leftUser: User(
                id: "1", name: "Saya Jones", score: 1225,
                imageURL: "saya_profile"),
            rightUser: User(
                id: "3", name: "Bruno Souto", score: 1168,
                imageURL: "bruno_profile"),
            timeLeft: "1d 11h left"
        ),
        Matchup(
            leftUser: User(
                id: "1", name: "Saya Jones", score: 1175,
                imageURL: "saya_profile"),
            rightUser: User(
                id: "4", name: "Judah Levine", score: 1113,
                imageURL: "judah_profile"),
            timeLeft: "1d 11h left"
        ),
    ]

    private let pendingInvitations = [
        PendingInvitation(
            user: User(
                id: "5", name: "Danielle Dolan", score: 0,
                imageURL: "profile_chris"),
            type: .accept
        ),
        PendingInvitation(
            user: User(
                id: "6", name: "Adson Afonso", score: 0, imageURL: "profile_bruno"
            ),
            type: .remind
        ),
    ]

    var body: some View {
        VStack(spacing: 20) {
            HomeHeader()
            
            // Live Matchups Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Live Matchups")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.horizontal)

                VStack(spacing: 12) {
                    ForEach(liveMatchups, id: \.leftUser.id) { matchup in
                        MatchupCard(matchup: matchup)
                    }
                }
                .padding(.horizontal)
            }

            // Pending Invitations Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Pending Invitations")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.horizontal)

                VStack(spacing: 12) {
                    ForEach(pendingInvitations, id: \.user.id) { invitation in
                        InvitationCard(invitation: invitation)
                    }
                }
                .padding(.horizontal)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

#Preview {
    SignInView()
}
