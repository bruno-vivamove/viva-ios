# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a SwiftUI-based iOS fitness social app called "Viva" that enables users to create fitness matchups/competitions with friends, track health data via HealthKit, and compete in various workout challenges.

## Architecture

**MVVM Pattern**: The app follows Model-View-ViewModel architecture with:
- **Models**: Data structures in `/Viva/Models/` (User, Matchup, Stats, Workout, etc.)
- **Views**: SwiftUI views organized by feature in `/Viva/Views/`
- **ViewModels**: Feature-specific ViewModels (HomeViewModel, ProfileViewModel, etc.)
- **Services**: Business logic and API communication in `/Viva/Services/`

**State Management**: 
- Global state via `AppState` class as `@ObservableObject`
- User authentication via `UserSession` and `AuthenticationManager`
- Reactive updates using Combine and `@Published` properties

## Key Services Architecture

**Networking Layer** (`/Services/Common/`):
- `NetworkClient<ErrorType>`: Generic HTTP client with automatic token refresh
- `RequestBuilder`: Constructs URLs and headers
- `ResponseHandler`: Processes responses with type-safe error handling
- `TokenRefreshHandler`: Manages JWT token lifecycle

**Service Organization**:
- Feature-specific services (AuthService, UserService, MatchupService, etc.)
- All services use the common NetworkClient for consistency
- Error handling via `VivaErrorResponse` and global `ErrorManager`

**HealthKit Integration**:
- Comprehensive health data queries in `/HealthData/`
- Background task management for health data sync
- Privacy-aware health data collection

## Environment Configuration

**Multi-Environment Setup**:
- Dev: `Viva - Dev (Debug).xcscheme`
- Local: `Viva - Local (Debug).xcscheme` 
- Production: `Viva - Prod (Debug).xcscheme`

Each environment has separate Info.plist files with different API endpoints and configuration.

## Design System

**Comprehensive Design System** (`VivaDesign.swift`):
- Semantic color system with brand colors (Viva Green: #00FFBE)
- Typography scale (Display, Heading, Title, Body, Label variants)
- Spacing system (layout, component, content spacing)
- Component variants (ButtonVariant, CardVariant)
- Animation system with predefined timing curves

**Usage**: Access via `VivaDesign.Colors.primary`, `VivaDesign.Typography.titleLarge`, etc.

## Dependencies

**Swift Package Manager** dependencies:
- **Alamofire (5.10.2)**: HTTP networking
- **GoogleSignIn-iOS (8.0.0)**: Google OAuth
- **Lottie (4.5.1)**: Animations  
- **Nuke (12.8.0)**: Image loading/caching
- **Swift Collections (1.1.4)**: Advanced data structures

## Development Commands

**Standard Xcode Project**: 
- Build: Use Xcode schemes or `⌘+B`
- Run: Select target scheme and `⌘+R`
- Test: `⌘+U` for unit tests

**Scheme Selection**: Choose appropriate scheme based on target environment:
- Development/testing: "Viva - Dev (Debug)" 
- Local testing: "Viva - Local (Debug)"
- Production builds: "Viva - Prod (Debug)"

## Logging System

**Structured Logging** (`AppLogger.swift`):
- Categories: `.network`, `.auth`, `.ui`, `.data`, `.general`
- Privacy-aware logging with automatic masking
- Integration with Apple's Console.app for debugging

**Usage**: `AppLogger.info("Message", category: .network)`

## Key Development Patterns

- **Background Tasks**: HealthKit background observers and data sync
- **Authentication**: Multi-provider OAuth with JWT token management  
- **Image Caching**: Custom Nuke pipeline configuration
- **Error Handling**: Global error management with user-friendly messaging
- **Reactive Programming**: Combine framework with `@Published` properties