# Documentation Structure

This folder contains comprehensive documentation for the Viva iOS app, organized to support both active development and long-term maintenance.

## Folder Structure

```
docs/
├── readme.md                    # This file - documentation overview
├── [living-documents].md        # Up-to-date documentation on app aspects
├── plans/                       # Active project and task plans
│   ├── [project-name].md        # Specific project plans with checkboxes
│   └── [feature-name].md        # Feature development plans
├── completed/                   # Completed plans archive
│   ├── [completed-project].md   # Finished project documentation
│   └── [completed-feature].md   # Completed feature plans
└── archive/                     # Historical documentation
    ├── [deprecated-docs].md     # Outdated documentation
    └── [old-decisions].md       # Historical technical decisions
```

## Document Types

### Living Documents (Root Level)
These are actively maintained documents that reflect the current state of the app. They should be updated as the codebase evolves.

**Technical Aspects:**
- `health-data.md` - HealthKit integration, data flow, and architecture
- `networking.md` - API architecture, NetworkClient, and service patterns
- `authentication.md` - Auth flow, security, and session management
- `notifications.md` - Push notifications and local notification system
- `app-architecture.md` - Overall app structure, MVVM patterns, and conventions
- `build-configuration.md` - Multi-environment setup, schemes, and deployment
- `dependencies.md` - SPM packages, version management, and integration

**Functional Aspects:**
- `matchups.md` - Matchup system, rules, and user flows
- `friends.md` - Friend system, invitations, and social features
- `user-profiles.md` - User management, profiles, and settings
- `onboarding.md` - User onboarding flow and first-time experience
- `design-system.md` - UI components, colors, typography, and patterns

**Process & Development:**
- `testing.md` - Comprehensive testing strategy and best practices
- `coding-standards.md` - Code style, patterns, and best practices
- `debugging-guide.md` - Common issues, logging, and troubleshooting
- `performance.md` - Performance monitoring, optimization, and benchmarks

### Plans Folder
Active project and task plans using checkbox format for tracking progress. These are working documents for current development.

**Project Plans:**
- Major feature implementations
- Architectural refactors
- Performance optimization initiatives
- Security improvements

**Task Plans:**
- Bug fix investigations
- Code cleanup tasks
- Testing implementations
- Documentation updates

**Creating New Plans:**
Use the `_template.md` file in the plans folder as a starting point for new project or task plans.

### Completed Folder
Archive of finished plans that can serve as:
- Reference for similar future work
- Documentation of what was accomplished
- Historical record of decision-making process

### Archive Folder
Historical documentation that's no longer current but may have value:
- Deprecated technical approaches
- Old architectural decisions
- Previous versions of living documents
- Legacy feature documentation

## Documentation Standards

### Writing Guidelines
- **Clear and Concise**: Write for developers who may be new to the project
- **Code Examples**: Include relevant code snippets and usage patterns
- **Visual Aids**: Use diagrams, flowcharts, or ASCII art where helpful
- **Cross-References**: Link between related documents
- **Date Stamps**: Include last updated dates for time-sensitive information

### Maintenance
- **Living Documents**: Review and update quarterly or when major changes occur
- **Plans**: Move to completed folder when finished
- **Archive**: Move outdated documents rather than deleting them

### Naming Conventions
- Use kebab-case for file names (`health-data.md`, `user-profiles.md`)
- Be descriptive but concise
- Include version numbers for major revisions if needed

## Getting Started

### For New Developers
1. Start with `app-architecture.md` for overall understanding
2. Read relevant functional docs for your work area
3. Review `coding-standards.md` and `debugging-guide.md`
4. Check `testing-plan.md` for testing expectations

### For Feature Development
1. Create a plan in the `plans/` folder
2. Update relevant living documents as you build
3. Move completed plan to `completed/` when finished
4. Update any cross-referenced documentation

### For Maintenance
1. Review living documents quarterly
2. Archive outdated information
3. Update cross-references when structure changes
4. Ensure new features have proper documentation

## Contributing to Documentation

Documentation is as important as code. When making changes:

1. **Update living documents** when functionality changes
2. **Create plans** for significant work before starting
3. **Cross-reference** related documentation
4. **Write for your future self** and teammates
5. **Include examples** and practical guidance

Good documentation saves time, reduces bugs, and helps the team move faster. Treat it as a first-class citizen in the development process.