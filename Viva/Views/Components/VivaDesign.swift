//
//  VivaDesign.swift
//  Viva
//
//  Created by Bruno Souto on 1/12/25.
//

import SwiftUI

enum VivaDesign {
    enum Colors {
        static let vivaGreen = Color(
            red: 0 / 255, green: 255 / 255, blue: 190 / 255)
        static let background = Color.black
        static let primaryText = Color.white
        static let secondaryText = Color.gray
        static let error = Color.red
        static let cardBorder = Color.white.opacity(1)
        static let divider = Color.white.opacity(0.3)
        static let warning = Color.orange
        static let destructive = Color.red
    }

    enum Spacing {
        static let outerPadding: CGFloat = 12
        static let cardSpacing: CGFloat = 12

        static let xlarge: CGFloat = 44
        static let large: CGFloat = 32
        static let medium: CGFloat = 20
        static let small: CGFloat = 12
        static let xsmall: CGFloat = 8
        static let minimal: CGFloat = 2
    }

    enum Sizing {
        static let cornerRadius: CGFloat = 8
        static let borderWidth: CGFloat = 1
        static let buttonCornerRadius: CGFloat = 10
        static let buttonBorderWidth: CGFloat = 2

        enum ProfileImage: CGFloat {
            case xlarge = 150
            case large = 75
            case medium = 60
            case small = 50
            case mini = 30
        }
    }

    enum Typography {
        static func displayText(_ size: CGFloat = 70) -> Font {
            .system(size: size, weight: .bold)
        }

        static let title = Font.system(size: 60, weight: .bold)
        static let title2 = Font.title2
        static let title3 = Font.title3
        static let body = Font.body

        static let pointsTitle = Font.system(size: 15, weight: .bold)
        static let points = Font.system(size: 30, weight: .bold)

        static let header = Font.system(size: 18, weight: .bold)
        static let caption = Font.subheadline
        static let value = Font.title3
    }

    enum AnimationStyle {
        static let loadingShimmer = Animation.easeOut(duration: 1).delay(1)
            .repeatForever(
                autoreverses: false)
    }
}
