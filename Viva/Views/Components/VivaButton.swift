//
//  VivaButton.swift
//  Viva
//
//  Created by Bruno Souto on 1/12/25.
//

import Lottie
import SwiftUI

enum VivaButtonSize {
    case small   // For card buttons
    case medium  // For auth buttons  
    case large   // For matchup type buttons
    
    var minHeight: CGFloat {
        switch self {
        case .small: return 36
        case .medium: return 36  // Match auth buttons exactly
        case .large: return 60
        }
    }
    
    var font: Font {
        switch self {
        case .small: return VivaDesign.Typography.caption
        case .medium: return VivaDesign.Typography.body.bold()  // Match auth buttons
        case .large: return .system(size: 24, weight: .semibold)
        }
    }
    
    var lottieSize: CGFloat {
        switch self {
        case .small: return 20
        case .medium: return 30  // Match auth buttons
        case .large: return 40
        }
    }
    
    var verticalPadding: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return 8   // Match auth buttons
        case .large: return 16
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return 16  // Match auth buttons
        case .large: return 24
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .small: return VivaDesign.Sizing.cornerRadius
        case .medium: return VivaDesign.Sizing.buttonCornerRadius  // Match auth buttons
        case .large: return 8
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .small: return VivaDesign.Sizing.borderWidth
        case .medium: return VivaDesign.Sizing.buttonBorderWidth  // Match auth buttons
        case .large: return 1
        }
    }
}

enum VivaButtonStyle {
    case primary    // Green background
    case secondary  // Clear background, white border
    case white      // White background
    case outline    // Clear background, colored border
    
    func foregroundColor(for baseColor: Color = VivaDesign.Colors.vivaGreen) -> Color {
        switch self {
        case .primary:
            return .black
        case .secondary, .outline:
            return .white
        case .white:
            return .black
        }
    }
    
    func backgroundColor(for baseColor: Color = VivaDesign.Colors.vivaGreen) -> Color {
        switch self {
        case .primary:
            return baseColor
        case .secondary, .outline:
            return .clear
        case .white:
            return .white
        }
    }
    
    func borderColor(for baseColor: Color = VivaDesign.Colors.vivaGreen) -> Color {
        switch self {
        case .primary:
            return baseColor
        case .secondary, .outline:
            return .white
        case .white:
            return .white
        }
    }
}

struct VivaButton: View {
    let title: String
    let size: VivaButtonSize
    let style: VivaButtonStyle
    let image: Image?
    let width: CGFloat?
    let isLoading: Bool
    let action: () -> Void
    private let baseColor: Color
    
    // Computed property to determine the correct Lottie animation based on text color
    private var lottieAnimationName: String {
        let textColor = style.foregroundColor(for: baseColor)
        return textColor == .black ? "bounce_balls_black" : "bounce_balls_white"
    }
    
    init(
        title: String,
        size: VivaButtonSize = .medium,
        style: VivaButtonStyle = .primary,
        image: Image? = nil,
        width: CGFloat? = nil,
        baseColor: Color = VivaDesign.Colors.vivaGreen,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.size = size
        self.style = style
        self.image = image
        self.width = width
        self.baseColor = baseColor
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            if !isLoading {
                action()
            }
        }) {
            ZStack {
                // Always present content to maintain layout space
                HStack {
                    if let image = image {
                        image
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(style.foregroundColor(for: baseColor))
                    }

                    Text(title)
                        .font(size.font)
                        .foregroundColor(style.foregroundColor(for: baseColor))
                }
                .opacity(isLoading ? 0 : 1)
                
                // Lottie animation overlay when loading
                if isLoading {
                    LottieView(animation: .named(lottieAnimationName))
                        .playing(loopMode: .loop)
                        .frame(width: size.lottieSize, height: size.lottieSize)
                }
            }
            .frame(width: width)
            .frame(maxWidth: width == nil ? .infinity : nil)
            .frame(minHeight: size.minHeight)
            .padding(.vertical, size.verticalPadding)
            .padding(.horizontal, size.horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(style.backgroundColor(for: baseColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .stroke(
                        style.borderColor(for: baseColor),
                        lineWidth: size.borderWidth
                    )
            )
        }
        .disabled(isLoading)
    }
} 