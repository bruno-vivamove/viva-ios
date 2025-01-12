//
//  InvitationCard.swift
//  Viva
//
//  Created by Bruno Souto on 1/9/25.
//

import SwiftUI

struct InvitationCard: View {
    private let activeTabColor: Color = .white
    private let inactiveTabColor: UIColor = .lightGray

    private let buttonWidth: CGFloat = 90
    let invitation: PendingInvitation

    var body: some View {

        HStack {
            // Action Buttons Container
            VStack(spacing: 8) {
                Button(action: {
                    // Add action here
                }) {
                    Text(invitation.type == .accept ? "Accept" : "Remind")
                        .foregroundColor(.vivaGreen)
                        .font(.subheadline)
                        .frame(width: buttonWidth)  // Fixed width
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.vivaGreen, lineWidth: 1)
                        )
                }

                if invitation.type == .accept {
                    Button(action: {
                        // Add action here
                    }) {
                        Text("Delete")
                            .foregroundColor(.white)
                            .font(.subheadline)
                            .frame(width: buttonWidth)  // Fixed width
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(lineWidth: 1)
                            )
                    }
                } else {
                    // Invisible spacer to maintain consistent height
                    Color.clear
                        .frame(width: buttonWidth, height: 37)
                }
            }

            Spacer()

            // User Info
            HStack(spacing: 12) {
                Text(invitation.user.name)
                    .foregroundColor(.vivaGreen)
                    .font(.subheadline)

                Image(invitation.user.imageURL)
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
