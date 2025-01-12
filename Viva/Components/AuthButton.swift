//
//  AuthButton.swift
//  Viva
//
//  Created by Bruno Souto on 1/9/25.
//

import SwiftUI

struct AuthButton: View {
    private let buttonTextFontSize: CGFloat = 20
    private let buttonCornerRadius: CGFloat = 10
    private let buttonBorderWidth: CGFloat = 2

    let title: String
    let foregroundColor: Color
    let backgroundColor: Color
    let borderColor: Color
    let image: Image?
    let action: () -> Void

    init(
        title: String,
        foregroundColor: Color,
        backgroundColor: Color,
        borderColor: Color? = nil,
        image: Image? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor ?? backgroundColor
        self.image = image
        self.action = action
    }

    var body: some View {
        Button(action: self.action) {
            HStack {
                if let image = self.image {
                    image
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(foregroundColor)
                }
                Text(title)
                    .font(.system(size: buttonTextFontSize, weight: .bold))
                    .foregroundColor(foregroundColor)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: buttonCornerRadius)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: buttonCornerRadius)
                    .stroke(borderColor, lineWidth: buttonBorderWidth)
            )
        }
    }
}
