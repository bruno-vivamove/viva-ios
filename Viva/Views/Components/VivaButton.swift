//
//  VivaButton.swift
//  Viva
//
//  Created by Bruno Souto on 1/12/25.
//

import Lottie
import SwiftUI

// MARK: - Simplified Button Size System
enum VivaButtonSize {
    case small, medium, large
    
    var height: CGFloat {
        switch self {
        case .small: return VivaDesign.Sizing.buttonSmall
        case .medium: return VivaDesign.Sizing.buttonMedium
        case .large: return VivaDesign.Sizing.buttonLarge
        }
    }
    
    var font: Font {
        switch self {
        case .small: return VivaDesign.Typography.labelMedium
        case .medium: return VivaDesign.Typography.labelLarge
        case .large: return VivaDesign.Typography.labelLarge
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .small: return VivaDesign.Spacing.contentMedium
        case .medium: return VivaDesign.Spacing.contentLarge
        case .large: return VivaDesign.Spacing.componentMedium
        }
    }
    
    var iconSize: CGFloat {
        switch self {
        case .small: return VivaDesign.Sizing.iconSmall
        case .medium: return VivaDesign.Sizing.iconMedium
        case .large: return VivaDesign.Sizing.iconSmall
        }
    }
    
    var loadingSize: CGFloat {
        switch self {
        case .small: return 16
        case .medium: return 24
        case .large: return 32
        }
    }
}

// MARK: - Main Button Component
struct VivaButton: View {
    let title: String
    let variant: VivaDesign.ButtonVariant
    let size: VivaButtonSize
    let icon: Image?
    let iconPosition: IconPosition
    let width: VivaButtonWidth
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    enum IconPosition {
        case leading, trailing
    }
    
    enum VivaButtonWidth {
        case flexible, fixed(CGFloat), fullWidth
    }
    
    // Computed properties
    private var style: (background: Color, foreground: Color, border: Color) {
        if isDisabled {
            return (VivaDesign.Colors.disabled, VivaDesign.Colors.disabledContent, VivaDesign.Colors.disabled)
        }
        return variant.style
    }
    
    private var lottieAnimationName: String {
        style.foreground == .black ? "bounce_balls_black" : "bounce_balls_white"
    }
    
    // Initializers
    init(
        _ title: String,
        variant: VivaDesign.ButtonVariant = .primary,
        size: VivaButtonSize = .medium,
        icon: Image? = nil,
        iconPosition: IconPosition = .leading,
        width: VivaButtonWidth = .fullWidth,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.variant = variant
        self.size = size
        self.icon = icon
        self.iconPosition = iconPosition
        self.width = width
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            if !isLoading && !isDisabled {
                action()
            }
        }) {
            buttonContent
        }
        .buttonStyle(VivaButtonStyle(
            style: style,
            size: size,
            width: width,
            isPressed: $isPressed,
            pressedOpacity: variant.pressedOpacity
        ))
        .disabled(isLoading || isDisabled)
    }
    
    @ViewBuilder
    private var buttonContent: some View {
        ZStack {
            // Main content
            HStack(spacing: VivaDesign.Spacing.contentSmall) {
                if iconPosition == .leading, let icon = icon {
                    iconView(icon)
                }
                
                Text(title)
                    .font(size.font)
                    .lineLimit(1)
                
                if iconPosition == .trailing, let icon = icon {
                    iconView(icon)
                }
            }
            .opacity(isLoading ? 0 : 1)
            
            // Loading indicator
            if isLoading {
                LottieView(animation: .named(lottieAnimationName))
                    .playing(loopMode: .loop)
                    .frame(width: size.loadingSize, height: size.loadingSize)
            }
        }
    }
    
    private func iconView(_ icon: Image) -> some View {
        icon
            .resizable()
            .scaledToFit()
            .frame(width: size.iconSize, height: size.iconSize)
    }
}

// MARK: - Button Style
struct VivaButtonStyle: ButtonStyle {
    let style: (background: Color, foreground: Color, border: Color)
    let size: VivaButtonSize
    let width: VivaButton.VivaButtonWidth
    @Binding var isPressed: Bool
    let pressedOpacity: Double
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(style.foreground)
            .frame(height: size.height)
            .frame(width: buttonWidth)
            .frame(maxWidth: maxWidth)
            .padding(.horizontal, size.horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: VivaDesign.Sizing.radiusMedium)
                    .fill(style.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: VivaDesign.Sizing.radiusMedium)
                            .stroke(style.border, lineWidth: borderWidth)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? pressedOpacity : 1.0)
            .animation(VivaDesign.Animation.quick, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                isPressed = newValue
            }
    }
    
    private var buttonWidth: CGFloat? {
        switch width {
        case .fixed(let value): return value
        default: return nil
        }
    }
    
    private var maxWidth: CGFloat? {
        switch width {
        case .fullWidth: return .infinity
        case .flexible: return nil
        case .fixed: return nil
        }
    }
    
    private var borderWidth: CGFloat {
        style.border == .clear ? 0 : VivaDesign.Sizing.borderMedium
    }
}

// MARK: - Convenience Initializers and Extensions
extension VivaButton {
    // Common button types
    static func primary(_ title: String, size: VivaButtonSize = .medium, isLoading: Bool = false, action: @escaping () -> Void) -> VivaButton {
        VivaButton(title, variant: .primary, size: size, isLoading: isLoading, action: action)
    }
    
    static func secondary(_ title: String, size: VivaButtonSize = .medium, isLoading: Bool = false, action: @escaping () -> Void) -> VivaButton {
        VivaButton(title, variant: .secondary, size: size, isLoading: isLoading, action: action)
    }
    
    static func outline(_ title: String, size: VivaButtonSize = .medium, isLoading: Bool = false, action: @escaping () -> Void) -> VivaButton {
        VivaButton(title, variant: .outline, size: size, isLoading: isLoading, action: action)
    }
    
    static func ghost(_ title: String, size: VivaButtonSize = .medium, isLoading: Bool = false, action: @escaping () -> Void) -> VivaButton {
        VivaButton(title, variant: .ghost, size: size, isLoading: isLoading, action: action)
    }
    
    static func destructive(_ title: String, size: VivaButtonSize = .medium, isLoading: Bool = false, action: @escaping () -> Void) -> VivaButton {
        VivaButton(title, variant: .destructive, size: size, isLoading: isLoading, action: action)
    }
    
    // With icons
    func withIcon(_ icon: Image, position: IconPosition = .leading) -> VivaButton {
        VivaButton(
            title,
            variant: variant,
            size: size,
            icon: icon,
            iconPosition: position,
            width: width,
            isLoading: isLoading,
            isDisabled: isDisabled,
            action: action
        )
    }
    
    // Width modifiers
    func flexible() -> VivaButton {
        VivaButton(
            title,
            variant: variant,
            size: size,
            icon: icon,
            iconPosition: iconPosition,
            width: .flexible,
            isLoading: isLoading,
            isDisabled: isDisabled,
            action: action
        )
    }
    
    func fixedWidth(_ width: CGFloat) -> VivaButton {
        VivaButton(
            title,
            variant: variant,
            size: size,
            icon: icon,
            iconPosition: iconPosition,
            width: .fixed(width),
            isLoading: isLoading,
            isDisabled: isDisabled,
            action: action
        )
    }
} 
