# Viva App Logging System

## Overview

This document describes the logging system for the Viva iOS app, which uses Apple's `os.Logger` framework with custom extensions for better usability, categorization, and privacy handling.

## Key Features

- **Structured Logging**: Organized logs with proper context (file, function, line number)
- **Categorized**: Logs are grouped by functional area (network, auth, UI, etc.)
- **Privacy Controls**: Built-in privacy handling for sensitive information
- **Log Levels**: Different severity levels with appropriate visibility
- **Console Integration**: Seamless integration with Apple's Console.app
- **Debug Visibility**: Enhanced console visibility in DEBUG mode

## Log Categories

The logging system organizes logs into the following categories:

- `network`: For API calls, responses, and network-related operations
- `auth`: For authentication, authorization, and user session events
- `ui`: For user interface events and interactions
- `data`: For data management and persistence operations
- `general`: For general app events that don't fit in other categories

## Log Levels

The system supports the following log levels:

- `debug`: For detailed information useful during development
- `info`: For general information about app operation
- `log`: Standard log level for routine operations
- `warning`: For potential issues that don't disrupt operation
- `error`: For errors that affect functionality but don't crash the app
- `fault`: For severe issues that may cause crashes

## How to Use

### Basic Logging

```swift
// Simple logs
AppLogger.debug("Loaded user data", category: .data)
AppLogger.info("User tapped on settings button", category: .ui)
AppLogger.warning("API response slow", category: .network)
AppLogger.error("Failed to save user preferences", category: .data)
AppLogger.fault("Critical database error", category: .data)
```

### Context Information

The logger automatically includes context information (file, function, line):

```swift
// This will log something like:
// [AuthenticationManager.swift:45 signIn(email:password:)] User signed in successfully
AppLogger.info("User signed in successfully", category: .auth)
```

### Privacy Handling

Use the privacy extensions to properly handle sensitive data:

```swift
// Private data (fully redacted in logs)
AppLogger.info("Processing data for user: \(userId.logPrivate())", category: .data)

// Public data (fully visible in logs)
AppLogger.info("Processing feature: \(featureName.logPublic())", category: .general)

// Masked data (shows only last 4 characters)
AppLogger.info("Completing transaction: \(transactionId.logMasked())", category: .data)

// Sensitive data (shows brief info in debug, nothing in production)
AppLogger.info("User details: \(userDetails.logSensitive())", category: .data)
```

#### Privacy Handling Behaviors

The privacy handling methods behave differently in DEBUG vs RELEASE builds:

| Privacy Method    | DEBUG Mode                     | RELEASE Mode         |
|-------------------|--------------------------------|----------------------|
| `logPrivate()`    | `<private>`                    | Fully redacted       |
| `logPublic()`     | Original value                 | Original value       |
| `logMasked()`     | `****1234` (last 4 visible)    | `****1234`           |
| `logSensitive()`  | `A...(20 chars)`               | `<sensitive data>`   |

### Network Request/Response Logging

Special methods for network operations:

```swift
// Log request
AppLogger.request(
    url: url,
    method: "POST",
    headers: headers
)

// Log response
AppLogger.response(
    url: url,
    statusCode: 200
)
```

## Viewing Logs

### During Development (DEBUG mode)

In DEBUG builds, logs are printed to the console with:
- Timestamps
- Emoji indicators for log level
- Category information
- Context information (file, line, function)

Example:
```
🔍 [2023-07-25 14:22:35.123] [DEBUG] [Network] [NetworkClient.swift:125 performRequest()] Request started
```

### In Production

Logs are captured by the system and can be viewed in Console.app:

1. Open Console.app on macOS
2. Connect your device
3. Filter by your app's bundle identifier
4. Filter by category (subsystem) with: `subsystem:com.yourcompany.viva.network`

## Important: Migrating from NetworkLogger

⚠️ **NetworkLogger is deprecated and should not be used in new code.**

If you see code using the old `NetworkLogger`, it should be updated to use `AppLogger` directly:

```swift
// ❌ OLD WAY (DEPRECATED)
NetworkLogger.log(message: "Started request", level: .debug)
NetworkLogger.log(message: "Operation completed", level: .info)
NetworkLogger.log(message: "Request failed", level: .error)

// ✅ NEW WAY (PREFERRED)
AppLogger.debug("Started request", category: .network)
AppLogger.info("Operation completed", category: .network)
AppLogger.error("Request failed", category: .network)
```

The legacy `NetworkLogger` will forward calls to `AppLogger` but is only maintained for backward compatibility and will display deprecation warnings in DEBUG mode.

## Best Practices

1. **Always Use AppLogger Directly**: Never use the deprecated NetworkLogger
2. **Choose Appropriate Categories**: Select the most specific category for your log
3. **Use Correct Log Levels**: Match the severity with the appropriate level
4. **Protect Private Data**: Always use privacy methods for sensitive information:
   - `logPrivate()`: For highly sensitive data like emails, passwords
   - `logMasked()`: For IDs and account numbers where partial visibility is helpful
   - `logSensitive()`: For data you want to see in debug but never in production
5. **Be Descriptive**: Include enough context in messages to understand the event
6. **Don't Over-Log**: Avoid excessive logging, especially in performance-critical paths

## Troubleshooting

- If logs aren't appearing in Console.app, check if the appropriate log level is enabled
- For log persistence issues, ensure you're using appropriate log levels (debug logs aren't persisted long-term)
- If log context is missing, ensure you're using the standard logging methods and not bypassing the context parameters
- If privacy handling isn't working as expected, ensure you're using the `.logPrivate()` method style (not other approaches) 