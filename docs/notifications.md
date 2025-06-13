# FCM Push Notifications Testing Guide

This guide provides instructions for sending test push notifications to the Viva iOS app using Firebase Cloud Messaging (FCM).

## Prerequisites

### 1. Service Account Authentication

You need the service account JSON file with Firebase Admin permissions:
- **File**: `/Users/brunosouto/Development/data/viva-move-prod-c844f6f459f4.json`
- **Service Account**: `viva-svc-sa@viva-move-prod.iam.gserviceaccount.com`
- **Permissions**: `roles/firebase.admin` (already configured)

### 2. Authenticate with Service Account

```bash
# Activate the service account
gcloud auth activate-service-account --key-file=/Users/brunosouto/Development/data/viva-move-prod-c844f6f459f4.json

# Verify authentication
gcloud auth list
```

### 3. Get FCM Device Token

To send notifications, you need the FCM device token from your iOS app. This token is generated when:
- The app first launches and requests push notification permissions
- The app registers with FCM
- Look for logs like: `APNS Device Token: ...` or `FCM registration token: ...`

**Current Test Token**: `cyEa0Mr6Q0BwhtHiv9pHM4:APA91bGuAtox5H5_Rd60kWwXX9Aemks5KS3u8PFeyhEjLGo7YtK0sfEqBWYY8j8hLEAiG28AjF56ol5s42am0DczeWGxfI38sh_nxHbyRDP-Nog2o4EaiuE`

## FCM Notification Types

### 1. Basic Data Notification (Silent)

Sends data to the app without showing a visible notification:

```bash
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "d-N-XUbFNUfPrGN2oovTLo:APA91bGZVDD5JgyetMJVlThC6mQc4FZVnT1-O_bHkEmoWIlrqUYPsPU29TErclGxua_1W7TqyJlYkY8LShVkNk8lHB2V-Ugnx_X96KYB-Rl9F5bxAGOIsV8",
      "data": {
        "custom_data": "{\"action\":\"sync_health_data\",\"user_id\":\"test_user_123\"}"
      }
    }
  }' \
  https://fcm.googleapis.com/v1/projects/viva-move-development/messages:send
```

### 2. Background Sync Notification

Triggers background processing with `content-available` flag:

```bash
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "d-N-XUbFNUfPrGN2oovTLo:APA91bGZVDD5JgyetMJVlThC6mQc4FZVnT1-O_bHkEmoWIlrqUYPsPU29TErclGxua_1W7TqyJlYkY8LShVkNk8lHB2V-Ugnx_X96KYB-Rl9F5bxAGOIsV8",
      "data": {
        "custom_data": "{\"action\":\"sync_health_data\",\"user_id\":\"test_user_123\"}"
      },
      "apns": {
        "payload": {
          "aps": {
            "content-available": 1
          }
        }
      }
    }
  }' \
  https://fcm.googleapis.com/v1/projects/viva-move-development/messages:send
```

### 3. Visible Notification with Background Processing

Shows a notification and triggers background processing:

```bash
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "cyEa0Mr6Q0BwhtHiv9pHM4:APA91bGuAtox5H5_Rd60kWwXX9Aemks5KS3u8PFeyhEjLGo7YtK0sfEqBWYY8j8hLEAiG28AjF56ol5s42am0DczeWGxfI38sh_nxHbyRDP-Nog2o4EaiuE",
      "notification": {
        "title": "Health Sync",
        "body": "Syncing your latest health data"
      },
      "data": {
        "custom_data": "{\"action\":\"sync_health_data\",\"user_id\":\"test_user_123\"}"
      },
      "apns": {
        "payload": {
          "aps": {
            "content-available": 1
          }
        }
      }
    }
  }' \
  https://fcm.googleapis.com/v1/projects/viva-move-prod/messages:send
```

### 4. Advanced APNS Configuration

For more control over iOS-specific behavior:

```bash
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "cyEa0Mr6Q0BwhtHiv9pHM4:APA91bGuAtox5H5_Rd60kWwXX9Aemks5KS3u8PFeyhEjLGo7YtK0sfEqBWYY8j8hLEAiG28AjF56ol5s42am0DczeWGxfI38sh_nxHbyRDP-Nog2o4EaiuE",
      "data": {
        "custom_data": "{\"action\":\"sync_health_data\",\"user_id\":\"test_user_123\"}"
      },
      "apns": {
        "headers": {
          "apns-push-type": "background",
          "apns-priority": "5"
        },
        "payload": {
          "aps": {
            "content-available": 1
          }
        }
      }
    }
  }' \
  https://fcm.googleapis.com/v1/projects/viva-move-prod/messages:send
```

## Testing Custom Actions

The Viva app supports different actions in the `custom_data` field:

### Health Data Sync
```json
{
  "custom_data": "{\"action\":\"sync_health_data\",\"user_id\":\"test_user_123\"}"
}
```

### Custom User Actions
```json
{
  "custom_data": "{\"action\":\"refresh_user_data\",\"user_id\":\"actual_user_id\"}"
}
```

### Matchup Updates
```json
{
  "custom_data": "{\"action\":\"matchup_update\",\"matchup_id\":\"matchup_123\",\"user_id\":\"user_456\"}"
}
```

## Successful Response

A successful FCM request returns:
```json
{
  "name": "projects/viva-move-prod/messages/1749701154657660"
}
```

## Common Issues & Troubleshooting

### APNS Authentication Errors
If you get `InvalidProviderToken` errors:
1. Check Firebase Console → Cloud Messaging → iOS app configuration
2. Verify APNS key/certificate is valid and not expired
3. Ensure bundle ID matches exactly: `io.vivamove.Viva`

### Token Expiration
The `$(gcloud auth print-access-token)` command automatically gets fresh tokens, but if you get 401 errors:
```bash
# Re-authenticate the service account
gcloud auth activate-service-account --key-file=/Users/brunosouto/Development/data/viva-move-prod-c844f6f459f4.json
```

### Invalid FCM Token
If you get `INVALID_ARGUMENT` errors:
- The FCM token might be expired or invalid
- Generate a new token by reinstalling the app or clearing app data
- Check app logs for the latest FCM registration token

## Environment Configuration

- **Production Project**: `viva-move-prod`
- **Bundle ID**: `io.vivamove.Viva`
- **FCM Endpoint**: `https://fcm.googleapis.com/v1/projects/viva-move-prod/messages:send`

## Security Notes

- Keep the service account JSON file secure
- Don't commit FCM tokens to version control
- Rotate APNS keys regularly
- Monitor FCM usage in Firebase Console 