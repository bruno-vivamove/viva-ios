//
//  VivaDesign.swift
//  Viva
//
//  Created by Bruno Souto on 1/12/25.
//

import SwiftUI

enum VivaDesign {
    
    // MARK: - Semantic Color System
    enum Colors {
        // Brand Colors
        static let primary = Color(red: 0/255, green: 255/255, blue: 190/255) // Viva Green
        static let secondary = Color.white
        
        // Semantic Colors
        static let background = Color(red: 11/255, green: 11/255, blue: 11/255)
        static let surface = Color(red: 11/255, green: 11/255, blue: 11/255)
        static let surfaceVariant = Color.gray.opacity(0.1)
        
        // Text Colors
        static let onPrimary = Color.black
        static let onSecondary = Color.black
        static let onBackground = Color.white
        static let onSurface = Color.white
        static let onSurfaceVariant = Color.gray
        
        // State Colors
        static let success = primary
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        
        // Interactive Colors
        static let border = Color.white
        static let borderVariant = Color.white.opacity(0.3)
        static let disabled = Color.gray
        static let disabledContent = Color.gray.opacity(0.6)
        
        // Legacy Support (to be phased out)
        static let vivaGreen = primary
        static let primaryText = onBackground
        static let secondaryText = onSurfaceVariant
        static let cardBorder = border
        static let divider = borderVariant
        static let destructive = error
    }
    
    // MARK: - Semantic Spacing System
    enum Spacing {
        // Layout Spacing
        static let introPadding: CGFloat = 32
        static let screenPadding: CGFloat = 16
        static let cardPadding: CGFloat = 12
        static let sectionSpacing: CGFloat = 32
        
        // Component Spacing
        static let componentLarge: CGFloat = 48
        static let componentMedium: CGFloat = 32
        static let componentSmall: CGFloat = 12
        static let componentTiny: CGFloat = 8
        
        // Content Spacing
        static let contentLarge: CGFloat = 32
        static let contentMedium: CGFloat = 24
        static let contentSmall: CGFloat = 14
        static let contentTiny: CGFloat = 8
        
        // Legacy Support
        static let large = contentLarge
        static let medium = contentMedium
        static let small = contentSmall
        static let xsmall = componentTiny

    }
    
    // MARK: - Component Sizing System
    enum Sizing {
        // Border Radius
        static let radiusSmall: CGFloat = 8
        static let radiusMedium: CGFloat = 12
        static let radiusLarge: CGFloat = 16
        static let radiusXLarge: CGFloat = 20
        
        // Border Width
        static let borderThin: CGFloat = 1
        static let borderMedium: CGFloat = 2
        static let borderThick: CGFloat = 3
        
        // Button Heights
        static let buttonSmall: CGFloat = 44
        static let buttonMedium: CGFloat = 52
        static let buttonLarge: CGFloat = 54
        
        // Icon Sizes
        static let iconSmall: CGFloat = 20
        static let iconMedium: CGFloat = 28
        static let iconLarge: CGFloat = 36
        
        // Profile Image Sizes
        enum ProfileImage: CGFloat, CaseIterable {
            case mini = 32
            case small = 50
            case medium = 65
            case large = 75
            case xlarge = 150
            case hero = 180
        }
        
        // Legacy Support
        static let cornerRadius = radiusMedium
        static let borderWidth = borderThin
        static let buttonCornerRadius = radiusMedium
        static let buttonBorderWidth = borderMedium
    }
    
    // MARK: - Typography System
    enum Typography {
        // Display Fonts (Made larger for more impact)
        static let displayLarge = Font.system(size: 80, weight: .bold)
        static let displayMedium = Font.system(size: 68, weight: .bold)
        static let displaySmall = Font.system(size: 56, weight: .bold)
        
        // Heading Fonts
        static let headingLarge = Font.system(size: 40, weight: .bold)
        static let headingMedium = Font.system(size: 32, weight: .bold)
        static let headingSmall = Font.system(size: 28, weight: .bold)
        
        // Title Fonts
        static let titleLarge = Font.system(size: 24, weight: .semibold)
        static let titleMedium = Font.system(size: 20, weight: .semibold)
        static let titleSmall = Font.system(size: 18, weight: .semibold)
        
        // Body Fonts
        static let bodyLarge = Font.system(size: 18, weight: .regular)
        static let bodyMedium = Font.system(size: 16, weight: .regular)
        static let bodySmall = Font.system(size: 14, weight: .regular)
        
        // Label Fonts
        static let labelLarge = Font.system(size: 16, weight: .medium)
        static let labelMedium = Font.system(size: 14, weight: .medium)
        static let labelSmall = Font.system(size: 12, weight: .medium)

        // Value Fonts
        static let valueLarge = Font.system(size: 20, weight: .regular)
        static let valueMedium = Font.system(size: 14, weight: .regular)
        static let valueSmall = Font.system(size: 12, weight: .regular)

        // Numeric Fonts
        static let numbersLarge = Font.system(size: 48, weight: .bold)
        static let numbersMedium = Font.system(size: 28, weight: .bold)
        static let numbersSmall = Font.system(size: 24, weight: .bold)
        
        // Legacy Support
        static func displayText(_ size: CGFloat = 68) -> Font {
            Font.system(size: size, weight: .bold)
        }
        static let title = displayMedium
        static let title2 = Font.title2
        static let title3 = Font.title3
        static let body = bodyLarge
        static let pointsTitle = labelMedium
        static let points = numbersMedium
        static let header = titleMedium
        static let caption = bodySmall
        static let value = titleSmall
    }
    
    // MARK: - Animation System
    enum Animation {
        static let quick = SwiftUI.Animation.easeOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let bounce = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.8)
        static let loading = SwiftUI.Animation.easeOut(duration: 1).delay(1).repeatForever(autoreverses: false)
        
        // Legacy Support
        static let loadingShimmer = loading
    }
    
    // MARK: - Layout Patterns
    enum Layout {
        // Screen Layout
        static let screenMaxWidth: CGFloat = 428 // iPhone 14 Pro Max width
        static let cardMaxWidth: CGFloat = 360
        
        // Safe Area Adjustments
        static let topSafeAreaOffset: CGFloat = 44
        static let bottomSafeAreaOffset: CGFloat = 34
        
        // Grid Patterns
        static let gridSpacing: CGFloat = 12
        static let minCardWidth: CGFloat = 150
    }
    
    // MARK: - Component Variants
    enum ButtonVariant {
        case primary, secondary, tertiary, outline, ghost, destructive
        
        var style: (background: Color, foreground: Color, border: Color) {
            switch self {
            case .primary:
                return (Colors.primary, Colors.onPrimary, Colors.primary)
            case .secondary:
                return (Colors.secondary, Colors.onSecondary, Colors.secondary)
            case .tertiary:
                return (Colors.background, Colors.onBackground, Colors.border)
            case .outline:
                return (Colors.background, Colors.onBackground, Colors.border)
            case .ghost:
                return (Colors.background, Colors.onBackground, .clear)
            case .destructive:
                return (Colors.error, Colors.secondary, Colors.error)
            }
        }
        
        var pressedOpacity: Double {
            switch self {
            case .primary, .secondary, .destructive: return 0.8
            case .tertiary, .outline, .ghost: return 0.6
            }
        }
    }
    
    enum CardVariant {
        case elevated, outlined, filled, minimal
        
        var style: (background: Color, border: Color, shadow: Bool) {
            switch self {
            case .elevated:
                return (Colors.surface, .clear, true)
            case .outlined:
                return (Colors.surface, Colors.border, false)
            case .filled:
                return (Colors.surfaceVariant, .clear, false)
            case .minimal:
                return (.clear, .clear, false)
            }
        }
    }
}

// MARK: - Design System Extensions
extension View {
    // Spacing Modifiers
    func screenPadding() -> some View {
        self.padding(.horizontal, VivaDesign.Spacing.screenPadding)
    }
    
    func cardPadding() -> some View {
        self.padding(VivaDesign.Spacing.cardPadding)
    }
    
    func sectionSpacing() -> some View {
        self.padding(.vertical, VivaDesign.Spacing.sectionSpacing)
    }
    
    // Layout Modifiers
    func vivaCard(_ variant: VivaDesign.CardVariant = .outlined) -> some View {
        let style = variant.style
        return self
            .padding(VivaDesign.Spacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: VivaDesign.Sizing.radiusMedium)
                    .fill(style.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: VivaDesign.Sizing.radiusMedium)
                            .stroke(style.border, lineWidth: style.border == .clear ? 0 : VivaDesign.Sizing.borderThin)
                    )
                    .shadow(
                        color: style.shadow ? .black.opacity(0.1) : .clear,
                        radius: style.shadow ? 8 : 0,
                        x: 0,
                        y: style.shadow ? 2 : 0
                    )
            )
    }
    
    // Content Layout
    func contentContainer() -> some View {
        self
            .frame(maxWidth: VivaDesign.Layout.screenMaxWidth)
            .screenPadding()
    }
}
