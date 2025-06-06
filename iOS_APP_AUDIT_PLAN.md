# Viva iOS App - Comprehensive Bug Fix and Security Audit Plan

This plan addresses critical bugs, security vulnerabilities, and configuration issues found in the Viva iOS fitness app. Items are prioritized by severity and impact on app stability.

## 🔴 CRITICAL PRIORITY (App Breaking Issues)

### Bundle Configuration & Force Unwrapping
- [ ] **Fix force unwrapping of Bundle configuration keys**
  - [ ] Replace force unwraps in `NetworkClientSettings.swift` (lines 14, 17, 22, 25)
  - [ ] Replace force unwrap in `AuthService.swift` (line 24) 
  - [ ] Add fallback values or proper error handling for missing Info.plist keys
  - [ ] Add missing `REFERER` key to `Info-local.plist`

- [ ] **Fix fatal errors that crash the app**
  - [ ] Replace `fatalError("No window available")` in `AuthenticationManager.swift` (line 218)
  - [ ] Replace `fatalError("Subclasses must implement execute method")` in `BaseHealthQuery.swift` (line 26)
  - [ ] Replace forced downcast in `BackgroundTaskManager.swift` (line 17)

### Memory Management Critical Issues
- [ ] **Fix retain cycles**
  - [ ] Fix Apple Sign In delegate retain cycle in `AuthenticationManager.swift` (line 158)
  - [ ] Add `[weak self]` to HealthKit observer closures in `HealthKitDataManager.swift` (lines 436-445)
  - [ ] Review and fix timer retention in `ErrorManager.swift` (lines 48-56)

## 🟡 HIGH PRIORITY (Security & Stability Issues)

### Security Vulnerabilities
- [ ] **Remove hardcoded secrets from Info.plist files**
  - [ ] Move Google API keys to secure configuration service
  - [ ] Move Google Client IDs to secure storage
  - [ ] Obfuscate or externalize API endpoints
  - [ ] Review all Info.plist files for exposed sensitive data

- [ ] **Implement proper Keychain security**
  - [ ] Add `kSecAttrAccessible` attributes to Keychain operations in `UserSession.swift`
  - [ ] Add biometric authentication protection for sensitive data
  - [ ] Move Apple user ID from UserDefaults to Keychain (`AuthenticationManager.swift` lines 76, 168)

- [ ] **Implement network security**
  - [ ] Add certificate pinning for all API communications
  - [ ] Implement TLS/SSL validation beyond default behavior
  - [ ] Add request signing or HMAC validation

### Xcode Project Configuration
- [ ] **Fix build configuration issues**
  - [ ] Fix Info.plist file assignments across build configurations in `project.pbxproj`
  - [ ] Add test target dependencies for `VivaTests` and `VivaUITests`
  - [ ] Consolidate duplicate package dependencies
  - [ ] Fix default build configurations for each target

- [ ] **Fix deployment and compatibility**
  - [ ] Lower deployment target from iOS 18.0 to iOS 15.0 or 16.0
  - [ ] Fix background task identifier inconsistencies in Info.plist files
  - [ ] Review bundle identifier patterns for consistency

## 🟠 MEDIUM PRIORITY (Potential Runtime Issues)

### Error Handling & Data Safety
- [ ] **Improve optional handling and bounds checking**
  - [ ] Fix force unwrapping of dictionary values in `MatchupDetailViewModel.swift` (lines 371, 381)
  - [ ] Add nil-safety checks for time interval calculations in `HomeViewModel.swift` (line 150)
  - [ ] Review and improve error handling in data loading operations

- [ ] **Fix threading and concurrency issues**
  - [ ] Ensure main thread access for UI updates in health data processing
  - [ ] Fix actor isolation issues in `UserSession.swift` (line 17)
  - [ ] Review token refresh handler concurrent request handling

### Input Validation & Data Integrity
- [ ] **Implement proper input validation**
  - [ ] Strengthen email validation beyond basic regex
  - [ ] Increase password requirements beyond 8 characters
  - [ ] Add input sanitization for user-generated content
  - [ ] Validate API parameter bounds and types

- [ ] **Improve data consistency**
  - [ ] Fix silent failures in keychain operations (`UserSession.swift`)
  - [ ] Add proper error handling for data cache initialization (`VivaApp.swift`)
  - [ ] Implement data integrity checks for stored session data

## 🟢 LOW PRIORITY (Best Practices & Performance)

### Resource Management
- [ ] **Improve resource cleanup**
  - [ ] Ensure proper cleanup of HealthKit background observers
  - [ ] Add automatic timer invalidation in error manager
  - [ ] Review memory usage in measurement processing operations

### Performance Optimizations
- [ ] **Optimize data processing**
  - [ ] Reduce duplicate data structures in `MatchupDetailViewModel.swift` (lines 376-392)
  - [ ] Add rate limiting for concurrent health data operations
  - [ ] Review and optimize background task management

### Logging and Privacy
- [ ] **Improve logging consistency**
  - [ ] Ensure consistent use of privacy extensions throughout app
  - [ ] Review log levels for production builds
  - [ ] Remove or mask any remaining sensitive data in logs

## QUESTIONS FOR DISCUSSION

Before proceeding with implementation, please clarify:

1. **API Key Security**: Do you have a preference for how to handle the hardcoded API keys? Options include:
   - Moving to a secure configuration service
   - Using build-time environment variables
   - Implementing runtime key fetching

2. **iOS Deployment Target**: What's the minimum iOS version you want to support? Current setting (iOS 18.0) is very restrictive.

3. **Certificate Pinning**: Do you have specific certificate pinning requirements or preferences for the networking layer?

4. **Testing Strategy**: Should we prioritize fixing test target dependencies to enable proper testing of these fixes?

5. **Release Timeline**: Are there any items that need to be deprioritized due to release deadlines?

## COMPLETION TRACKING

- **Critical Priority**: 0/10 completed
- **High Priority**: 0/12 completed  
- **Medium Priority**: 0/8 completed
- **Low Priority**: 0/6 completed

**Total Progress**: 0/36 items completed

---

*This audit was generated by analyzing the entire Viva iOS codebase for bugs, security vulnerabilities, and configuration issues. Each item includes specific file paths and line numbers for efficient resolution.*