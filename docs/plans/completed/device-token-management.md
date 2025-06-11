# Device Token Management for Push Notifications Plan

**Created:** December 9, 2024  
**Status:** Implementation Complete ✅  
**Priority:** High  

## Objective

Implement a comprehensive device token management system for Firebase Cloud Messaging (FCM) push notifications, ensuring reliable token registration, updates, and cleanup across user authentication states and app lifecycle events.

## Background

The Viva app requires device token management to enable silent push notifications for health data sync and matchup refresh. The backend uses Firebase FCM and provides REST endpoints for device token operations. We need a robust strategy to handle token registration, updates, and cleanup while managing edge cases like app reinstalls, user logouts, and token refresh.

## Technical Requirements

### 1. Device Token API Integration
- Use existing `/device-tokens` REST endpoints with Firebase FCM backend
- Support device token registration, updates, and deletion
- Handle platform-specific requirements (iOS vs Android)
- Include optional device name for identification

**DeviceTokenRequest Schema:**
```json
{
  "deviceToken": "string (required, max 255 chars)",
  "platform": "ios|android (required)",
  "deviceName": "string (optional, max 100 chars)"
}
```

### 2. Token Lifecycle Management
- Register token immediately after successful user authentication
- Update token when FCM refreshes the device token
- Delete token on user logout or app uninstall
- Handle token changes during app updates or device changes

### 3. Registration Strategy
- **When to register**: After successful login AND push notification permission granted
- **Token source**: Firebase FCM token (not Apple's device token)
- **Retry logic**: Handle network failures with exponential backoff
- **Duplicate handling**: Use PUT endpoint for updates, POST for initial registration

### 4. Error Handling & Edge Cases
- Network connectivity issues during registration
- Token refresh while app is backgrounded
- User logout with pending token operations
- App reinstall scenarios (old token cleanup)
- Multiple devices per user account

### 5. Service Architecture
- Create `DeviceTokenService` following existing service patterns
- Integrate with current `NetworkClient` architecture
- Use existing authentication and error handling systems
- Support background token operations

## Implementation Plan

### Phase 1: Core Service Implementation
- [ ] **DeviceTokenService Creation**
  - Create service class with register/update/delete methods
  - Follow existing service patterns with NetworkClient integration
  - Add proper error handling and retry logic
  - Include comprehensive logging for debugging

- [ ] **Model Creation**
  - Create `DeviceTokenRequest` model matching API schema
  - Add validation for platform and deviceToken format
  - Include helper methods for iOS-specific operations

### Phase 2: Firebase FCM Integration
- [ ] **FCM Token Management**
  - Add Firebase Messaging SDK dependency
  - Implement FCM token retrieval and refresh handling
  - Replace current APNS token usage with FCM tokens
  - Add FCM token change observers

- [ ] **Token Registration Flow**
  - Register FCM token after successful authentication
  - Handle push notification permission flow
  - Implement automatic token updates on refresh
  - Add device name from UIDevice.current.name

### Phase 3: Lifecycle Integration
- [ ] **Authentication Integration**
  - Register token in AuthenticationManager after login
  - Delete token in logout flow
  - Handle token registration failures gracefully
  - Add token validation before registration

- [ ] **App Lifecycle Handling**
  - Monitor FCM token changes in background
  - Handle app updates and reinstalls
  - Implement proper cleanup on app deletion
  - Add app state change monitoring

### Phase 4: Testing & Validation
- [ ] **Testing Strategy**
  - Unit tests for service methods and error handling
  - Integration tests for full registration flow
  - Test token refresh scenarios
  - Validate cleanup on logout/uninstall

- [ ] **Edge Case Testing**
  - Network failure during registration
  - Token refresh during background execution
  - Multiple rapid login/logout cycles
  - App reinstall and migration scenarios

## Current vs Future State

### Current State (Apple Push Notifications)
- Using APNS device tokens stored in UserDefaults
- Manual device token logging in AppDelegate
- No backend registration or management
- Silent notifications may not work reliably

### Future State (Firebase FCM)
- FCM tokens automatically registered with backend
- Proper lifecycle management and cleanup
- Reliable push notification delivery
- Support for targeted notifications and analytics

## Technical Considerations

### Firebase FCM vs APNS Integration
- FCM provides better cross-platform consistency
- FCM handles token refresh automatically
- Backend already configured for FCM
- Maintain APNS registration for iOS-specific features

### Token Storage and Security
- Store current FCM token in Keychain for security
- Track registration status to avoid duplicate calls
- Handle token changes without user intervention
- Implement secure token comparison for updates

### Background Operations
- Register token changes during background execution
- Handle network failures with background retry
- Ensure token operations don't affect app performance
- Use existing background task management patterns

### Multi-Device Support
- Support multiple devices per user account
- Unique device identification using token + device name
- Proper cleanup when switching between devices
- Handle device-specific notification preferences

## Success Criteria

- [ ] FCM tokens successfully registered on user login
- [ ] Automatic token updates when FCM refreshes tokens
- [ ] Proper token cleanup on user logout
- [ ] Reliable push notification delivery for all registered devices
- [ ] Graceful handling of network failures and edge cases

## Files to Create/Modify

### New Files
- [ ] `Viva/Models/DeviceTokenRequest.swift`
- [ ] `Viva/Services/DeviceTokenService.swift`

### Existing Files to Modify
- [ ] `Viva/App/VivaApp.swift` - FCM integration and token monitoring
- [ ] `Viva/App/VivaAppObjects.swift` - Add DeviceTokenService
- [ ] `Viva/AppState/AuthenticationManager.swift` - Token registration on login/logout
- [ ] `Package.swift` or Xcode project - Add Firebase Messaging dependency

## Dependencies

### Required
- [ ] Firebase Messaging SDK integration
- [ ] Existing NetworkClient and service architecture
- [ ] Current authentication and session management
- [ ] Push notification permission handling

### Optional Enhancements
- [ ] Device identification and naming
- [ ] Token analytics and monitoring
- [ ] Notification preference management
- [ ] Cross-platform token synchronization

## Risks & Mitigation

**Risk:** FCM SDK adds significant app size overhead  
**Mitigation:** Evaluate minimal FCM configuration, consider alternatives if size is critical

**Risk:** Token registration failures prevent push notifications  
**Mitigation:** Implement robust retry logic with exponential backoff and manual retry options

**Risk:** Multiple devices cause notification duplication  
**Mitigation:** Backend handles device-specific targeting, implement proper token cleanup

**Risk:** Network failures during critical token operations  
**Mitigation:** Queue token operations for retry, graceful degradation for offline scenarios

## Future Considerations

- **Analytics Integration**: Track token registration success rates and failures
- **Notification Preferences**: User control over notification types per device
- **Advanced Targeting**: Leverage FCM's user segmentation and targeting features
- **Cross-Platform Sync**: Coordinate notifications between iOS and Android apps
- **Token Migration**: Handle migration from current APNS-only system

## Implementation Notes

### Registration Flow
1. User completes authentication successfully
2. Request push notification permissions (if not already granted)
3. Retrieve FCM token from Firebase Messaging
4. Register token with backend via DeviceTokenService
5. Store registration status and token in Keychain
6. Monitor for token changes and update as needed

### Token Update Flow
1. FCM notifies app of token refresh
2. Retrieve new FCM token
3. Compare with stored token to detect changes
4. Update backend with new token via PUT endpoint
5. Update stored token in Keychain
6. Log successful update for monitoring

### Cleanup Flow
1. User initiates logout or app is uninstalled
2. Delete token from backend via DELETE endpoint
3. Clear stored token from Keychain
4. Reset registration status
5. Stop monitoring for token changes

This comprehensive approach ensures reliable push notification delivery while handling the complexities of device token management in a production iOS application.