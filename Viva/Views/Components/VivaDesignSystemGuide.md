# Viva Design System Guide

## Overview

The Viva Design System provides a comprehensive, semantic approach to building consistent and beautiful UI components across the app. It's organized around semantic tokens rather than visual properties, making it easier to maintain and update.

## Core Principles

1. **Semantic Over Visual**: Use semantic names (e.g., `primary`, `onBackground`) instead of visual descriptions (e.g., `green`, `white`)
2. **Consistency**: All components follow the same spacing, typography, and color patterns
3. **Accessibility**: Colors and sizing are designed with accessibility in mind
4. **Flexibility**: Components can be customized while maintaining consistency

## Design Tokens

### Colors

#### Brand Colors
```swift
VivaDesign.Colors.primary        // Viva Green - main brand color
VivaDesign.Colors.secondary      // White - secondary brand color
```

#### Semantic Colors
```swift
VivaDesign.Colors.background     // Main background color
VivaDesign.Colors.surface        // Card/surface backgrounds
VivaDesign.Colors.surfaceVariant // Alternative surface color

// Text colors - automatically contrast with their backgrounds
VivaDesign.Colors.onPrimary      // Text on primary color
VivaDesign.Colors.onBackground   // Text on background
VivaDesign.Colors.onSurface      // Text on surface
VivaDesign.Colors.onSurfaceVariant // Secondary text
```

#### State Colors
```swift
VivaDesign.Colors.success        // Success states
VivaDesign.Colors.warning        // Warning states
VivaDesign.Colors.error          // Error states
VivaDesign.Colors.info           // Info states
```

### Typography

#### Semantic Font Scales
```swift
// Display fonts for hero content
VivaDesign.Typography.displayLarge    // 72pt
VivaDesign.Typography.displayMedium   // 60pt
VivaDesign.Typography.displaySmall    // 48pt

// Headings for major sections
VivaDesign.Typography.headingLarge    // 36pt
VivaDesign.Typography.headingMedium   // 28pt
VivaDesign.Typography.headingSmall    // 24pt

// Titles for subsections
VivaDesign.Typography.titleLarge      // 22pt
VivaDesign.Typography.titleMedium     // 18pt
VivaDesign.Typography.titleSmall      // 16pt

// Body text
VivaDesign.Typography.bodyLarge       // 16pt
VivaDesign.Typography.bodyMedium      // 14pt
VivaDesign.Typography.bodySmall       // 12pt

// Labels and captions
VivaDesign.Typography.labelLarge      // 14pt medium
VivaDesign.Typography.labelMedium     // 12pt medium
VivaDesign.Typography.labelSmall      // 10pt medium

// Numeric content
VivaDesign.Typography.numbersLarge    // 48pt rounded
VivaDesign.Typography.numbersMedium   // 32pt rounded
VivaDesign.Typography.numbersSmall    // 24pt rounded
```

### Spacing

#### Semantic Spacing System
```swift
// Layout spacing
VivaDesign.Spacing.screenPadding     // 16pt - main screen padding
VivaDesign.Spacing.cardPadding       // 16pt - internal card padding
VivaDesign.Spacing.sectionSpacing    // 24pt - between major sections

// Component spacing
VivaDesign.Spacing.componentLarge    // 32pt - large component gaps
VivaDesign.Spacing.componentMedium   // 20pt - standard component gaps
VivaDesign.Spacing.componentSmall    // 12pt - small component gaps
VivaDesign.Spacing.componentTiny     // 8pt - minimal gaps

// Content spacing
VivaDesign.Spacing.contentLarge      // 24pt - large content gaps
VivaDesign.Spacing.contentMedium     // 16pt - standard content gaps
VivaDesign.Spacing.contentSmall      // 8pt - small content gaps
VivaDesign.Spacing.contentTiny       // 4pt - minimal content gaps
```

### Sizing

#### Border Radius
```swift
VivaDesign.Sizing.radiusSmall        // 6pt
VivaDesign.Sizing.radiusMedium       // 8pt - standard radius
VivaDesign.Sizing.radiusLarge        // 12pt
VivaDesign.Sizing.radiusXLarge       // 16pt
```

#### Component Sizes
```swift
// Button heights
VivaDesign.Sizing.buttonSmall        // 36pt
VivaDesign.Sizing.buttonMedium       // 44pt
VivaDesign.Sizing.buttonLarge        // 52pt

// Icon sizes
VivaDesign.Sizing.iconSmall          // 16pt
VivaDesign.Sizing.iconMedium         // 24pt
VivaDesign.Sizing.iconLarge          // 32pt

// Profile image sizes
VivaDesign.Sizing.ProfileImage.mini     // 24pt
VivaDesign.Sizing.ProfileImage.small    // 40pt
VivaDesign.Sizing.ProfileImage.medium   // 60pt
VivaDesign.Sizing.ProfileImage.large    // 80pt
VivaDesign.Sizing.ProfileImage.xlarge   // 120pt
VivaDesign.Sizing.ProfileImage.hero     // 150pt
```

## Components

### Buttons

#### Basic Usage
```swift
// Simple buttons with semantic variants
VivaButton.primary("Sign Up") { /* action */ }
VivaButton.secondary("Cancel") { /* action */ }
VivaButton.outline("Learn More") { /* action */ }
VivaButton.ghost("Skip") { /* action */ }
VivaButton.destructive("Delete") { /* action */ }

// With loading states
VivaButton.primary("Save", isLoading: isLoading) { /* action */ }

// With icons
VivaButton.primary("Sign In")
    .withIcon(Image("google_logo"))
    { /* action */ }

// Custom widths
VivaButton.primary("Submit")
    .flexible()  // Hugs content
    .fixedWidth(200)  // Fixed width
    // Default is full width
```

#### Advanced Usage
```swift
VivaButton(
    "Custom Button",
    variant: .primary,
    size: .large,
    icon: Image(systemName: "plus"),
    iconPosition: .trailing,
    width: .flexible,
    isLoading: false,
    isDisabled: false
) { /* action */ }
```

### Cards

#### Basic Cards
```swift
// Standard outlined card (default)
VivaCard {
    Text("Card content")
}

// Different variants
VivaCard.elevated {
    Text("Elevated card with shadow")
}

VivaCard.filled {
    Text("Filled card with background")
}

VivaCard.minimal {
    Text("Minimal card with no styling")
}
```

#### Specialized Cards
```swift
// Info card for key-value pairs
VivaInfoCard(
    title: "Steps Today",
    value: "8,423",
    subtitle: "Goal: 10,000",
    icon: Image(systemName: "figure.walk")
)

// Profile card
VivaProfileCard(
    name: "John Doe",
    subtitle: "Online now",
    profileImage: Image("profile"),
    imageSize: .medium,
    trailing: AnyView(
        Text("Score: 150")
            .font(VivaDesign.Typography.labelMedium)
    )
) { /* tap action */ }

// Status card
VivaStatusCard(
    title: "Health Data",
    status: .success,
    message: "All data synced successfully"
) { /* tap action */ }
```

### Layout Components

#### Screen Layout
```swift
VivaScreen {
    VStack {
        // Your content here
    }
}
```

#### Sections
```swift
VivaSection {
    VivaSectionHeader("Recent Activity")
} content: {
    // Section content
}

// With action
VivaSection {
    VivaSectionHeader(
        "Matchups",
        actionTitle: "See All"
    ) { /* see all action */ }
} content: {
    // Section content
}
```

#### Display Headers
```swift
VivaDisplayHeader(
    "LONG LIVE",
    subtitle: "THE FIT",
    image: Image("viva_logo"),
    alignment: .trailing
)
```

#### Grids and Lists
```swift
// Grid layout
VivaGrid(items, columns: 2) { item in
    // Grid item content
}

// List layout
VivaList(items) { item in
    // List item content
}
```

### State Views

#### Loading States
```swift
VivaLoadingView("Loading your data...")
```

#### Empty States
```swift
VivaEmptyStateView(
    title: "No Matchups",
    message: "Create your first matchup to get started",
    image: Image(systemName: "trophy"),
    actionTitle: "Create Matchup"
) { /* create action */ }
```

### Form Components

```swift
VivaFormField(
    "Email Address",
    isRequired: true,
    error: emailError
) {
    TextField("Enter your email", text: $email)
        .textFieldStyle(VivaTextFieldStyle())
}
```

### Utility Components

#### Dividers
```swift
VivaDivider()  // Standard divider
VivaDivider(color: VivaDesign.Colors.primary, thickness: 2)  // Custom
```

#### Spacers
```swift
VivaSpacers.small     // 8pt spacer
VivaSpacers.medium    // 16pt spacer
VivaSpacers.large     // 24pt spacer
VivaSpacers.component // 20pt spacer
VivaSpacers.section   // 24pt spacer
```

## View Extensions

### Layout Helpers
```swift
someView.screenPadding()    // Adds horizontal screen padding
someView.cardPadding()      // Adds card padding
someView.sectionSpacing()   // Adds section spacing
someView.contentContainer() // Centers content with max width
someView.vivaCard(.outlined) // Wraps in a card
```

## Migration Guide

### From Old System to New

#### Colors
```swift
// Old
VivaDesign.Colors.vivaGreen
VivaDesign.Colors.primaryText

// New (semantic)
VivaDesign.Colors.primary
VivaDesign.Colors.onBackground

// Legacy colors are still available for gradual migration
```

#### Typography
```swift
// Old
.font(VivaDesign.Typography.header)

// New (semantic)
.font(VivaDesign.Typography.titleMedium)
```

#### Buttons
```swift
// Old
VivaButton(
    title: "Sign Up",
    style: .primary,
    size: .medium
) { /* action */ }

// New (simpler)
VivaButton.primary("Sign Up") { /* action */ }
```

## Best Practices

1. **Use Semantic Colors**: Always use semantic color names (`onBackground` not `white`)
2. **Consistent Spacing**: Use the spacing tokens instead of hardcoded values
3. **Component Composition**: Build complex UIs by composing simple components
4. **Loading States**: Always provide loading states for async operations
5. **Empty States**: Provide helpful empty states with clear actions
6. **Accessibility**: Use semantic typography scales for proper accessibility

## Examples

### Simple Screen
```swift
VivaScreen {
    VStack(spacing: VivaDesign.Spacing.sectionSpacing) {
        VivaDisplayHeader("Welcome")
        
        VivaSection {
            VivaSectionHeader("Quick Actions")
        } content: {
            VStack(spacing: VivaDesign.Spacing.componentSmall) {
                VivaButton.primary("Create Matchup") { /* action */ }
                VivaButton.secondary("View History") { /* action */ }
            }
        }
    }
}
```

### Complex Card Layout
```swift
VivaCard {
    VStack(spacing: VivaDesign.Spacing.contentMedium) {
        HStack {
            Text("Daily Progress")
                .font(VivaDesign.Typography.titleMedium)
                .foregroundColor(VivaDesign.Colors.onSurface)
            Spacer()
            Text("Today")
                .font(VivaDesign.Typography.labelMedium)
                .foregroundColor(VivaDesign.Colors.onSurfaceVariant)
        }
        
        HStack {
            VivaInfoCard(
                title: "Steps",
                value: "8,423",
                subtitle: "Goal: 10,000"
            )
            
            VivaInfoCard(
                title: "Calories",
                value: "324",
                subtitle: "Goal: 500"
            )
        }
    }
}
```

This design system provides a solid foundation for building consistent, accessible, and maintainable UI components while being flexible enough to handle unique design requirements. 