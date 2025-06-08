# SwiftLint Setup and ViewModel Anti-Pattern Prevention

## Overview
This document explains the SwiftLint configuration designed to prevent ViewModel anti-patterns and maintain code quality in the Viva iOS project.

## Installation

### 1. Install SwiftLint
```bash
# Using Homebrew (recommended)
brew install swiftlint

# Or using Mint
mint install realm/SwiftLint

# Or using CocoaPods (add to Podfile)
pod 'SwiftLint'
```

### 2. Xcode Integration
Add a new "Run Script Phase" to your target's build phases:

1. Open Xcode project
2. Select your target
3. Go to "Build Phases" tab
4. Click "+" and select "New Run Script Phase"
5. Add this script:
```bash
if which swiftlint >/dev/null; then
    swiftlint
else
    echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi
```

Or use the provided script:
```bash
"${SRCROOT}/scripts/swiftlint-build-phase.sh"
```

## Custom Rules for ViewModel Anti-Patterns

### 1. ViewModel in Navigation Closure (ERROR)
**Rule**: `viewmodel_in_navigation`
**Pattern**: Detects ViewModel creation in `.navigationDestination` closures

```swift
// ❌ This will trigger an error
.navigationDestination(item: $selectedItem) { item in
    DetailView(viewModel: DetailViewModel(id: item.id)) // ERROR!
}

// ✅ This is correct
.navigationDestination(item: $selectedItem) { item in
    DetailView(itemId: item.id, source: "navigation")
}
```

### 2. ViewModel in Sheet Closure (ERROR)
**Rule**: `viewmodel_in_sheet`
**Pattern**: Detects ViewModel creation in `.sheet` closures

```swift
// ❌ This will trigger an error
.sheet(isPresented: $showSheet) {
    DetailView(viewModel: DetailViewModel(id: "123")) // ERROR!
}

// ✅ This is correct
.sheet(isPresented: $showSheet) {
    DetailView(itemId: "123", source: "sheet")
}
```

### 3. @State with ObservableObject (WARNING)
**Rule**: `state_with_observable_object`
**Pattern**: Detects `@State` used with ViewModels

```swift
// ⚠️ This will trigger a warning
@State private var viewModel: MyViewModel? // WARNING!

// ✅ This is correct
@StateObject private var viewModel: MyViewModel
```

### 4. @ObservedObject ViewModel Warning (WARNING)
**Rule**: `observed_object_viewmodel`
**Pattern**: Suggests considering @StateObject for ViewModels

```swift
// ⚠️ This will trigger a warning
@ObservedObject var viewModel: MyViewModel // WARNING: Consider @StateObject

// ✅ This is usually correct
@StateObject private var viewModel: MyViewModel
```

## Running SwiftLint

### Command Line
```bash
# Run linting
swiftlint

# Auto-fix correctable issues
swiftlint --fix

# Lint specific files
swiftlint lint --path Viva/Views/

# Generate configuration
swiftlint rules > swiftlint-rules.txt
```

### Xcode Integration
SwiftLint will run automatically during build if properly configured, showing warnings and errors in the Issue Navigator.

## Configuration Details

### File Structure
```
├── .swiftlint.yml           # Main configuration
├── scripts/
│   └── swiftlint-build-phase.sh  # Build script
└── docs/
    └── SwiftLint-Setup.md   # This documentation
```

### Key Settings
- **Line Length**: 120 characters (warning), 140 (error)
- **Function Length**: 50 lines (warning), 80 (error)
- **File Length**: 500 lines (warning), 800 (error)
- **Cyclomatic Complexity**: 10 (warning), 15 (error)

### Excluded Paths
- Test files (`VivaTests/`, `VivaUITests/`)
- Build artifacts (`DerivedData`, `.build`)
- Preview content
- External dependencies

## Custom Rule Explanations

### Why These Rules Matter

1. **Memory Leaks Prevention**: Navigation closure rules prevent the memory leaks we fixed in the ViewModel audit
2. **Performance**: Ensures single ViewModel instances instead of multiple
3. **Consistency**: Enforces the established patterns across the codebase
4. **Maintainability**: Makes ViewModel lifecycle management predictable

### Rule Accuracy

The regex patterns are designed to catch common anti-patterns while minimizing false positives:

- **High Precision**: Rules target specific problematic patterns
- **Context Aware**: Rules consider the closure context (navigation, sheet, etc.)
- **Severity Levels**: Errors for critical anti-patterns, warnings for style issues

## Disabling Rules

### Per-File
```swift
// swiftlint:disable rule_name
// Code that needs to disable the rule
// swiftlint:enable rule_name
```

### Per-Line
```swift
let problematicCode = something() // swiftlint:disable:this rule_name
```

### Globally (in .swiftlint.yml)
```yaml
disabled_rules:
  - rule_name
```

## CI/CD Integration

### GitHub Actions
```yaml
- name: SwiftLint
  run: |
    brew install swiftlint
    swiftlint --strict
```

### Fastlane
```ruby
lane :lint do
  swiftlint(
    strict: true,
    config_file: ".swiftlint.yml"
  )
end
```

## Maintenance

### Updating Rules
1. Review new SwiftLint releases for relevant rules
2. Monitor false positives and adjust patterns
3. Add new anti-pattern rules as they're discovered
4. Update documentation when rules change

### Team Training
1. Share this documentation with all developers
2. Include SwiftLint output in code review process
3. Regular team discussions about code quality
4. Update onboarding to include SwiftLint setup

## Troubleshooting

### Common Issues

1. **SwiftLint not found**: Ensure SwiftLint is installed and in PATH
2. **Too many warnings**: Gradually enable rules or adjust thresholds
3. **False positives**: Use inline disable comments or adjust regex patterns
4. **Build slowdown**: Consider running SwiftLint in a separate build phase

### Performance Tips

- Exclude unnecessary paths to speed up linting
- Use `--cache-path` for faster subsequent runs
- Consider running only on changed files in CI

## Results Expected

After implementing these linting rules:

1. **Zero ViewModel Anti-Patterns**: Rules catch problematic patterns before merge
2. **Consistent Code Style**: Automated enforcement of established patterns
3. **Reduced Code Review Time**: Automated checks reduce manual review needs
4. **Better Code Quality**: Proactive prevention of common issues
5. **Team Alignment**: Shared understanding of best practices

## Integration with Existing Workflow

This SwiftLint configuration complements the ViewModel best practices documentation and provides automated enforcement of the patterns established during the anti-pattern audit and fixes.

## Resources

- [SwiftUI ViewModel Best Practices](./swiftui-viewmodel-best-practices.md)
- [Coding Standards](./coding-standards.md)
- [Memory Testing Guide](./memory-testing-guide.md)
- [ViewModel Anti-Pattern Fix Plan](./plans/viewmodel-creation-fix.md)