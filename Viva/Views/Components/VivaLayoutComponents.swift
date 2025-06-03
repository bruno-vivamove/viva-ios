//
//  VivaLayoutComponents.swift
//  Viva
//
//  Created by Bruno Souto on 1/12/25.
//

import SwiftUI

// MARK: - Screen Layout Components

/// A standardized screen container that provides consistent padding and layout
struct VivaScreen<Content: View>: View {
    let content: Content
    let hasNavigationBar: Bool
    let backgroundColor: Color
    
    init(
        hasNavigationBar: Bool = true,
        backgroundColor: Color = VivaDesign.Colors.background,
        @ViewBuilder content: () -> Content
    ) {
        self.hasNavigationBar = hasNavigationBar
        self.backgroundColor = backgroundColor
        self.content = content()
    }
    
    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(backgroundColor)
            .contentContainer()
    }
}

/// A section container with optional header and consistent spacing
struct VivaSection<Header: View, Content: View>: View {
    let header: Header?
    let content: Content
    let spacing: CGFloat
    
    init(
        spacing: CGFloat = VivaDesign.Spacing.componentMedium,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self.header = header()
        self.content = content()
        self.spacing = spacing
    }
    
    init(
        spacing: CGFloat = VivaDesign.Spacing.componentMedium,
        @ViewBuilder content: () -> Content
    ) where Header == EmptyView {
        self.header = nil
        self.content = content()
        self.spacing = spacing
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            if let header = header {
                header
            }
            content
        }
    }
}

// MARK: - Header Components

/// A standardized section header with title and optional action
struct VivaSectionHeader: View {
    let title: String
    let subtitle: String?
    let action: (() -> Void)?
    let actionTitle: String
    
    init(
        _ title: String,
        subtitle: String? = nil,
        actionTitle: String = "See All",
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: VivaDesign.Spacing.contentTiny) {
            HStack {
                VStack(alignment: .leading, spacing: VivaDesign.Spacing.contentTiny) {
                    Text(title)
                        .font(VivaDesign.Typography.titleSmall)
                        .foregroundColor(VivaDesign.Colors.onBackground)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(VivaDesign.Typography.bodySmall)
                            .foregroundColor(VivaDesign.Colors.onSurfaceVariant)
                    }
                }
                
                Spacer()
                
                if let action = action {
                    Button(actionTitle) {
                        action()
                    }
                    .font(VivaDesign.Typography.labelMedium)
                    .foregroundColor(VivaDesign.Colors.primary)
                }
            }
        }
    }
}

/// A large display header for main screens
struct VivaDisplayHeader: View {
    let title: String
    let subtitle: String?
    let image: Image?
    let alignment: HorizontalAlignment
    
    init(
        _ title: String,
        subtitle: String? = nil,
        image: Image? = nil,
        alignment: HorizontalAlignment = .leading
    ) {
        self.title = title
        self.subtitle = subtitle
        self.image = image
        self.alignment = alignment
    }
    
    var body: some View {
        VStack(alignment: alignment, spacing: VivaDesign.Spacing.contentSmall) {
            if let image = image {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(height: 60)
            }
            
            VStack(alignment: alignment, spacing: VivaDesign.Spacing.contentTiny) {
                Text(title)
                    .font(VivaDesign.Typography.displayMedium)
                    .foregroundColor(VivaDesign.Colors.primary)
                    .multilineTextAlignment(alignment == .leading ? .leading : .trailing)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(VivaDesign.Typography.titleMedium)
                        .foregroundColor(VivaDesign.Colors.onBackground)
                        .multilineTextAlignment(alignment == .leading ? .leading : .trailing)
                }
            }
        }
    }
}

// MARK: - Content Layout Components

/// A grid layout for cards or tiles
struct VivaGrid<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let columns: Int
    let spacing: CGFloat
    let content: (Item) -> Content
    
    init(
        _ items: [Item],
        columns: Int = 2,
        spacing: CGFloat = VivaDesign.Spacing.componentSmall,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.columns = columns
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns),
            spacing: spacing
        ) {
            ForEach(items) { item in
                content(item)
            }
        }
    }
}

/// A list layout with consistent styling
struct VivaList<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let spacing: CGFloat
    let content: (Item) -> Content
    
    init(
        _ items: [Item],
        spacing: CGFloat = VivaDesign.Spacing.componentSmall,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        LazyVStack(spacing: spacing) {
            ForEach(items) { item in
                content(item)
            }
        }
    }
}

// MARK: - State Views

/// A loading state view with consistent styling
struct VivaLoadingView: View {
    let message: String
    
    init(_ message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: VivaDesign.Spacing.componentMedium) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(VivaDesign.Colors.primary)
            
            Text(message)
                .font(VivaDesign.Typography.bodyMedium)
                .foregroundColor(VivaDesign.Colors.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VivaDesign.Colors.background)
    }
}

/// An empty state view with consistent styling
struct VivaEmptyStateView: View {
    let title: String
    let message: String
    let image: Image?
    let action: (() -> Void)?
    let actionTitle: String
    
    init(
        title: String,
        message: String,
        image: Image? = nil,
        actionTitle: String = "Try Again",
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.image = image
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: VivaDesign.Spacing.componentLarge) {
            VStack(spacing: VivaDesign.Spacing.componentMedium) {
                if let image = image {
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                        .foregroundColor(VivaDesign.Colors.onSurfaceVariant)
                }
                
                VStack(spacing: VivaDesign.Spacing.contentSmall) {
                    Text(title)
                        .font(VivaDesign.Typography.titleLarge)
                        .foregroundColor(VivaDesign.Colors.onBackground)
                        .multilineTextAlignment(.center)
                    
                    Text(message)
                        .font(VivaDesign.Typography.bodyMedium)
                        .foregroundColor(VivaDesign.Colors.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                }
            }
            
            if let action = action {
                VivaButton.outline(actionTitle, action: action)
                    .flexible()
            }
        }
        .padding(VivaDesign.Spacing.componentLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VivaDesign.Colors.background)
    }
}

// MARK: - Form Components

/// A form field container with consistent styling
struct VivaFormField<Content: View>: View {
    let label: String
    let isRequired: Bool
    let error: String?
    let content: Content
    
    init(
        _ label: String,
        isRequired: Bool = false,
        error: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.label = label
        self.isRequired = isRequired
        self.error = error
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: VivaDesign.Spacing.contentSmall) {
            HStack(spacing: VivaDesign.Spacing.contentTiny) {
                Text(label)
                    .font(VivaDesign.Typography.labelMedium)
                    .foregroundColor(VivaDesign.Colors.onBackground)
                
                if isRequired {
                    Text("*")
                        .font(VivaDesign.Typography.labelMedium)
                        .foregroundColor(VivaDesign.Colors.error)
                }
            }
            
            content
            
            if let error = error {
                Text(error)
                    .font(VivaDesign.Typography.bodySmall)
                    .foregroundColor(VivaDesign.Colors.error)
            }
        }
    }
}

// MARK: - Dividers and Spacers

/// Semantic spacers for consistent spacing
struct VivaSpacers {
    static var small: some View {
        Spacer().frame(height: VivaDesign.Spacing.contentSmall)
    }
    
    static var medium: some View {
        Spacer().frame(height: VivaDesign.Spacing.contentMedium)
    }
    
    static var large: some View {
        Spacer().frame(height: VivaDesign.Spacing.contentLarge)
    }
    
    static var component: some View {
        Spacer().frame(height: VivaDesign.Spacing.componentMedium)
    }
    
    static var section: some View {
        Spacer().frame(height: VivaDesign.Spacing.sectionSpacing)
    }
} 
