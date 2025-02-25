//
//  VivaSecondaryButton.swift
//  Viva
//
//  Created by Bruno Souto on 1/12/25.
//

import SwiftUI

struct CardButton: View {
    let title: String
    let width: CGFloat?
    let action: () -> Void
    let color: Color

    init(title: String, width: CGFloat? = nil, color: Color = .primary, action: @escaping () -> Void) {
        self.title = title
        self.width = width
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(color)
                .font(VivaDesign.Typography.caption)
                .frame(width: width)
                .padding(VivaDesign.Spacing.minimal)
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
        }
    }
}
