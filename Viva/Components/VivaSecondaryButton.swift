//
//  VivaSecondaryButton.swift
//  Viva
//
//  Created by Bruno Souto on 1/12/25.
//

import SwiftUI

struct VivaSecondaryButton: View {
    let title: String
    let width: CGFloat?
    let action: () -> Void

    init(title: String, width: CGFloat? = nil, action: @escaping () -> Void) {
        self.title = title
        self.width = width
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(VivaDesign.Colors.primaryText)
                .font(VivaDesign.Typography.caption)
                .frame(width: width)
                .padding(VivaDesign.Spacing.minimal)
                .background(
                    RoundedRectangle(
                        cornerRadius: VivaDesign.Sizing
                            .cornerRadius
                    )
                    .stroke(
                        VivaDesign.Colors.primaryText,
                        lineWidth: VivaDesign.Sizing.borderWidth
                    )
                )
        }
    }
}
