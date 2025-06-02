//
//  VivaSecondaryButton.swift
//  Viva
//
//  Created by Bruno Souto on 1/12/25.
//

import Lottie
import SwiftUI

struct CardButton: View {
    let title: String
    let width: CGFloat?
    let action: () -> Void
    let color: Color
    let isLoading: Bool

    init(title: String, width: CGFloat? = nil, color: Color = .primary, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.width = width
        self.color = color
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                // Always present text to maintain layout space
                Text(title)
                    .foregroundColor(color)
                    .font(VivaDesign.Typography.caption)
                    .opacity(isLoading ? 0 : 1)
                
                // Lottie animation overlay when loading
                if isLoading {
                    LottieView(animation: .named("bounce_balls_white"))
                        .playing(loopMode: .loop)
                        .frame(width: 20, height: 20)
                }
            }
            .frame(width: width)
            .frame(minWidth: 44) // Ensure minimum button size
            .padding(VivaDesign.Spacing.xsmall)
            .background(
                RoundedRectangle(
                    cornerRadius: VivaDesign.Sizing
                        .cornerRadius
                )
                .stroke(
                    color,
                    lineWidth: VivaDesign.Sizing.borderWidth
                )
            )
            .lineLimit(1)
        }
        .disabled(isLoading)
    }
}
