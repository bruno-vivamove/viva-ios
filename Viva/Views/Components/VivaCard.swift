//
//  VivaCard.swift
//  Viva
//
//  Created by Bruno Souto on 1/12/25.
//

import SwiftUI

// MARK: - Enhanced Card System

/// A flexible card component with various styling options
struct VivaCard<Content: View>: View {
    let content: Content
    let variant: VivaDesign.CardVariant
    let padding: CGFloat
    let isInteractive: Bool
    let action: (() -> Void)?
    
    @State private var isPressed = false
    
    init(
        variant: VivaDesign.CardVariant = .outlined,
        padding: CGFloat = VivaDesign.Spacing.cardPadding,
        isInteractive: Bool = false,
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.variant = variant
        self.padding = padding
        self.isInteractive = isInteractive
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Group {
            if isInteractive || action != nil {
                Button(action: action ?? {}) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .animation(VivaDesign.Animation.quick, value: isPressed)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in isPressed = true }
                        .onEnded { _ in isPressed = false }
                )
            } else {
                cardContent
            }
        }
    }
    
    @ViewBuilder
    private var cardContent: some View {
        let style = variant.style
        
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: VivaDesign.Sizing.radiusMedium)
                    .fill(style.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: VivaDesign.Sizing.radiusSmall)
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
}

// MARK: - Specialized Card Components

/// A card specifically designed for displaying key-value information
struct VivaInfoCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: Image?
    let variant: VivaDesign.CardVariant
    let action: (() -> Void)?
    
    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: Image? = nil,
        variant: VivaDesign.CardVariant = .outlined,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.variant = variant
        self.action = action
    }
    
    var body: some View {
        VivaCard(variant: variant, action: action) {
            VStack(spacing: VivaDesign.Spacing.contentSmall) {
                if let icon = icon {
                    HStack {
                        icon
                            .resizable()
                            .scaledToFit()
                            .frame(width: VivaDesign.Sizing.iconMedium, height: VivaDesign.Sizing.iconMedium)
                            .foregroundColor(VivaDesign.Colors.primary)
                        Spacer()
                    }
                }
                
                VStack(alignment: .leading, spacing: VivaDesign.Spacing.contentTiny) {
                    HStack {
                        Text(title)
                            .font(VivaDesign.Typography.labelMedium)
                            .foregroundColor(VivaDesign.Colors.onSurfaceVariant)
                        Spacer()
                    }
                    
                    HStack {
                        Text(value)
                            .font(VivaDesign.Typography.numbersSmall)
                            .foregroundColor(VivaDesign.Colors.onBackground)
                        Spacer()
                    }
                    
                    if let subtitle = subtitle {
                        HStack {
                            Text(subtitle)
                                .font(VivaDesign.Typography.bodySmall)
                                .foregroundColor(VivaDesign.Colors.primary)
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}

/// A card for user profile information
struct VivaProfileCard: View {
    let name: String
    let subtitle: String?
    let profileImage: Image?
    let imageSize: VivaDesign.Sizing.ProfileImage
    let trailing: AnyView?
    let action: (() -> Void)?
    
    init(
        name: String,
        subtitle: String? = nil,
        profileImage: Image? = nil,
        imageSize: VivaDesign.Sizing.ProfileImage = .medium,
        trailing: AnyView? = nil,
        action: (() -> Void)? = nil
    ) {
        self.name = name
        self.subtitle = subtitle
        self.profileImage = profileImage
        self.imageSize = imageSize
        self.trailing = trailing
        self.action = action
    }
    
    var body: some View {
        VivaCard(isInteractive: action != nil, action: action) {
            HStack(spacing: VivaDesign.Spacing.contentMedium) {
                // Profile Image
                Group {
                    if let profileImage = profileImage {
                        profileImage
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(VivaDesign.Colors.onSurfaceVariant)
                    }
                }
                .frame(width: imageSize.rawValue, height: imageSize.rawValue)
                .clipShape(Circle())
                
                // Name and Subtitle
                VStack(alignment: .leading, spacing: VivaDesign.Spacing.contentTiny) {
                    Text(name)
                        .font(VivaDesign.Typography.titleSmall)
                        .foregroundColor(VivaDesign.Colors.onBackground)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(VivaDesign.Typography.bodySmall)
                            .foregroundColor(VivaDesign.Colors.onSurfaceVariant)
                    }
                }
                
                Spacer()
                
                // Trailing Content
                if let trailing = trailing {
                    trailing
                }
            }
        }
    }
}

/// A card for displaying status information
struct VivaStatusCard: View {
    let title: String
    let status: StatusType
    let message: String?
    let action: (() -> Void)?
    
    enum StatusType {
        case success, warning, error, info
        
        var color: Color {
            switch self {
            case .success: return VivaDesign.Colors.success
            case .warning: return VivaDesign.Colors.warning
            case .error: return VivaDesign.Colors.error
            case .info: return VivaDesign.Colors.info
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
    
    init(
        title: String,
        status: StatusType,
        message: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.status = status
        self.message = message
        self.action = action
    }
    
    var body: some View {
        VivaCard(variant: .filled, action: action) {
            HStack(spacing: VivaDesign.Spacing.contentMedium) {
                Image(systemName: status.icon)
                    .foregroundColor(status.color)
                    .frame(width: VivaDesign.Sizing.iconMedium)
                
                VStack(alignment: .leading, spacing: VivaDesign.Spacing.contentTiny) {
                    Text(title)
                        .font(VivaDesign.Typography.titleSmall)
                        .foregroundColor(VivaDesign.Colors.onBackground)
                    
                    if let message = message {
                        Text(message)
                            .font(VivaDesign.Typography.bodySmall)
                            .foregroundColor(VivaDesign.Colors.onSurfaceVariant)
                    }
                }
                
                Spacer()
                
                if action != nil {
                    Image(systemName: "chevron.right")
                        .foregroundColor(VivaDesign.Colors.onSurfaceVariant)
                        .font(.system(size: 12, weight: .medium))
                }
            }
        }
    }
}

// MARK: - Convenience Extensions

// Note: Static factory methods removed due to generic type conversion issues
// Use VivaCard(variant: .elevated) { ... } instead
