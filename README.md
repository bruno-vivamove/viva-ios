# Viva iOS App

Viva is a health and fitness competition platform that allows users to challenge each other in team-based competitions (called "matchups") to track and compare various health metrics like steps, exercise activities, energy burned, and more. The iOS app gamifies health tracking by creating friendly competitions and leveraging social connections.

## Project Overview

This SwiftUI-based iOS fitness social app enables users to create fitness matchups/competitions with friends, track health data via HealthKit, and compete in various workout challenges. The app focuses on social fitness engagement through team-based competitions and real-time health data sharing.

## Technical Architecture

### Technology Stack

- **Framework**: SwiftUI with iOS 14.0+ deployment target
- **Architecture**: MVVM (Model-View-ViewModel) pattern
- **State Management**: Combine framework with `@ObservableObject` and `@Published` properties
- **Networking**: Custom NetworkClient built on Alamofire with automatic token refresh
- **Health Data**: HealthKit integration with background observers
- **Authentication**: JWT-based with refresh tokens, Google and Apple OAuth
- **Dependencies**: Swift Package Manager with Alamofire, GoogleSignIn, Firebase, Lottie, Nuke

### Project Structure

```
Viva/
├── App/                      # App lifecycle and configuration
├── AppState/                 # Global state management  
├── Models/                   # Data models and DTOs
├── Services/                 # Business logic layer
│   └── Common/               # Shared networking infrastructure
├── HealthData/               # HealthKit integration
├── Views/                    # SwiftUI views and UI
│   ├── Components/           # Reusable UI components
│   ├── Home/                 # Main dashboard
│   ├── Matchup/              # Competition views
│   ├── Friends/              # Social features
│   └── Profile/              # User management
└── [Multi-environment configs]
```

## Core Domain Model

### Matchups (Competitions)
- **Matchup**: Team-based competition between LEFT and RIGHT sides with states (PENDING, ACTIVE, COMPLETED, CANCELLED)
- **Measurement Types**: Steps, energy burned, workout durations (running, cycling, etc.), body states (sleep, heart rate)
- **Point System**: Multipliers normalize different activity types for fair competition
- **Rematch System**: Preserves team compositions for follow-up competitions

### Users and Social Features
- **Authentication**: OAuth (Google, Apple) with JWT tokens stored securely in Keychain
- **Friend System**: Bidirectional connections with request/accept flows
- **User Profiles**: Display name, stats, friend status, and competition history

### Health Data Integration
- **HealthKit**: Comprehensive data collection with background observers and privacy controls
- **Workouts**: Exercise sessions that automatically contribute to active matchups
- **Daily Tracking**: Day-by-day measurement recording throughout competition duration

*For detailed API integration, see backend service documentation.*

## System Architecture

### MVVM Pattern
- **Views**: SwiftUI declarative UI components
- **ViewModels**: `@ObservableObject` classes managing view state and business logic
- **Services**: Feature-specific business logic (Auth, Matchup, Health, etc.)
- **Models**: Data structures and networking layer

### Key Components
- **NetworkClient**: Generic HTTP client with automatic retry and token refresh
- **HealthKitDataManager**: Central coordinator for health data collection and background sync
- **UserSession**: Authentication state management with secure Keychain storage
- **Design System**: Comprehensive UI framework in `VivaDesign.swift`

*For detailed networking patterns, see `/Services/Common/NetworkClient.swift`*  
*For health data implementation, see `/docs/health-data.md`*

## Environment Configuration

The app supports three environments with separate schemes and configurations:

- **Development**: `Viva - Dev (Debug)` scheme with `Info-dev.plist`
- **Local Testing**: `Viva - Local (Debug)` scheme with `Info-local.plist`  
- **Production**: `Viva - Prod` scheme with `Info-prod.plist`

Each environment has dedicated:
- Info.plist files with API endpoints and OAuth keys
- GoogleService-Info.plist files for Firebase configuration
- Entitlements for app capabilities and permissions

## Design System

`VivaDesign.swift` provides a comprehensive design system with semantic colors (brand Viva Green #00FFBE), typography scale, spacing system, and component variants (buttons, cards, animations).

*For complete design guidelines, see `/Views/Components/VivaDesignSystemGuide.md`*

## Key Workflows

### Authentication
OAuth flow (Google/Apple) → JWT token exchange → secure Keychain storage with biometric protection

### Matchup Management
Create competition → invite friends → team balancing → start competition → daily health tracking → final scoring → rematch options

### Health Data Sync
HealthKit authorization → background observers → daily queries → point calculation → backend sync → participant notifications

*For detailed workflow diagrams, see `/docs/` folder documentation*

## API Integration

The app communicates with a Java/Quarkus backend service through feature-specific services (`AuthService`, `MatchupService`, `UserService`, etc.) using a custom `NetworkClient` with automatic token refresh and retry logic.

**Key API Operations**: Authentication, user management, matchup CRUD, friend connections, health data uploads  
**Data Models**: Type-safe DTOs for all requests/responses with structured error handling  
**Real-time Updates**: Push notifications for competition and social updates

*For complete API documentation, see backend service README*

## Security and Privacy

### Authentication
- JWT tokens with automatic refresh stored in Keychain with biometric protection
- OAuth integration (Google, Apple) with secure session management

### Health Data Privacy
- Granular HealthKit permissions with user consent
- Local processing and minimal data transfer to backend
- Privacy-first design with clear user controls

### Security Features
- Biometric authentication for app access
- Secure API communication with certificate pinning
- Privacy-aware logging with sensitive data masking

*For detailed security implementation, see `/docs/` security documentation*

## Development Setup

### Prerequisites
- Xcode 14.0+ with iOS 14.0+ deployment target
- Apple Developer Account (for device testing and HealthKit)
- Pure Swift Package Manager project (no CocoaPods)

### Local Setup
1. Clone repository and open `Viva.xcodeproj`
2. Select build scheme (`Viva - Dev (Debug)` for development)
3. Configure environment-specific Info.plist and GoogleService-Info.plist files
4. Build and run on device or simulator

*HealthKit requires physical device testing*

### Testing and Debugging

**Testing**: Unit tests in `VivaTests/` (ViewModels, services, models) and UI tests in `VivaUITests/` (critical flows, navigation, accessibility)

**Logging**: Structured logging system with categories (auth, network, health, UI) and privacy-aware sensitive data masking

*For detailed testing strategy, see `/docs/testing-plan.md`*  
*For debugging guide, see `/docs/memory-testing-guide.md`*

## Performance Considerations

### Key Optimizations
- **Memory Management**: ARC optimization with retain cycle prevention in ViewModels
- **Image Caching**: Custom Nuke pipeline with 50MB memory + 100MB disk cache
- **Network Efficiency**: Request batching, intelligent caching, exponential backoff retry logic
- **Health Data**: Optimized HealthKit queries with date ranges and proper observer cleanup

*For performance benchmarks and memory testing, see `/docs/memory-testing-guide.md`*

## Deployment

### Build Process
- **Development**: Use `Viva - Dev (Debug)` scheme for testing
- **Production**: Use `Viva - Prod` scheme for App Store builds
- **TestFlight**: Internal beta distribution for validation
- **App Store**: Archive and upload via Xcode Organizer

*For production deployment checklist, see `/docs/plans/production-deployment-readiness.md`*

## Documentation

Comprehensive documentation located in `/docs/` folder:

**Technical Documentation**:
- `health-data.md` - HealthKit integration and architecture
- `notifications.md` - Push notification implementation  
- `coding-standards.md` - Development best practices
- `swiftui-viewmodel-best-practices.md` - MVVM patterns

**Development Plans**:
- `plans/` - Active project plans with progress tracking
- `plans/completed/` - Archived completed projects
- `iOS_APP_AUDIT_PLAN.md` - Security and architecture audit progress

*See `/docs/readme.md` for complete documentation structure*

## Contributing

### Development Workflow
1. Create feature plan in `/docs/plans/` folder
2. Follow MVVM patterns and established coding standards
3. Write comprehensive tests (70% coverage target for services)
4. Update relevant documentation
5. Manual device testing for HealthKit functionality

*For detailed coding standards, see `/docs/coding-standards.md`*

## Troubleshooting

### Common Issues
- **Build Failures**: Verify scheme selection and Swift Package Manager dependencies
- **HealthKit**: Test on physical devices, check entitlements and privacy descriptions
- **Authentication**: Validate OAuth client IDs and Keychain configuration
- **Networking**: Confirm API endpoints match selected environment

### Debugging Tools
- **AppLogger**: Structured logging with privacy-aware masking
- **Xcode Instruments**: Performance profiling and memory analysis
- **Console.app**: Device logs for background processing issues

*For detailed troubleshooting guide, see `/docs/` folder*

## Future Enhancements

**Planned Features**: Advanced analytics, challenges system, Apple Watch app, expanded social features, gamification  
**Technical Improvements**: Performance optimization, offline support, accessibility, expanded testing, CI/CD pipeline  
**Architecture**: Modularization, newer SwiftUI features, enhanced Combine patterns

*For detailed roadmap, see `/docs/plans/` folder*

---

## Quick Start Guide

**New Developers**:
1. Follow development setup instructions
2. Review MVVM patterns and `/docs/readme.md`
3. Run `Viva - Dev (Debug)` scheme for testing
4. Create test matchup to experience core functionality

**For AI Agents**: This README provides architectural overview. Refer to `/docs/` folder for detailed technical implementation and backend service documentation for API details.