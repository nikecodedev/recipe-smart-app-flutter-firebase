# Firebase Cloud Messaging (FCM) Setup Guide

This guide explains how to set up and deploy Firebase Cloud Messaging for push notifications in the Recipe Smart App.

## Prerequisites

1. Firebase project with Cloud Functions enabled
2. Node.js 18+ installed
3. Firebase CLI installed: `npm install -g firebase-tools`
4. Flutter app with Firebase configured

## Part 1: Cloud Functions Setup

### 1. Initialize Firebase Functions

```bash
# Navigate to project root
cd recipe-smart-app-flutter-firebase

# Initialize Firebase (if not already done)
firebase init functions

# Select:
# - JavaScript (or TypeScript if preferred)
# - ESLint (optional)
# - Install dependencies now
```

### 2. Install Dependencies

```bash
cd functions
npm install firebase-admin firebase-functions
```

### 3. Deploy Functions

```bash
# Deploy all functions
firebase deploy --only functions

# Or deploy specific function
firebase deploy --only functions:sendExpiryAlerts
```

### 4. Test Functions

```bash
# Test manually via HTTP endpoint (if manualExpiryAlerts is deployed)
curl -X POST https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/manualExpiryAlerts

# Or use Firebase Console > Functions > Test function
```

## Part 2: Flutter App Setup

### 1. Android Configuration

#### Update `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        // ... existing config
        minSdkVersion 21 // Required for FCM
    }
}

dependencies {
    // ... existing dependencies
    implementation 'com.google.firebase:firebase-messaging:23.4.0'
}
```

#### Create Notification Channel (`android/app/src/main/kotlin/.../MainActivity.kt`):

```kotlin
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "pantry_alerts",
                "Pantry Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for expiring pantry items"
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
}
```

### 2. iOS Configuration

#### Update `ios/Runner/Info.plist`:

```xml
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

#### Update `ios/Runner/AppDelegate.swift`:

```swift
import UIKit
import Flutter
import Firebase
import FirebaseMessaging

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { _, _ in }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }
    
    application.registerForRemoteNotifications()
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func application(_ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
  }
}
```

### 3. Initialize FCM in Flutter

The FCM service is already integrated in `lib/services/notifications/fcm_service.dart` and initialized in `main.dart`.

### 4. Update User Profile with FCM Token

The token is automatically saved when the user logs in. The `NotificationNotifier` handles this.

## Part 3: Testing

### 1. Test FCM Token Registration

1. Run the app
2. Check logs for "FCM Token obtained"
3. Verify token is saved in Firestore: `/users/{userId}/fcmToken`

### 2. Test Manual Notification

Use Firebase Console:
1. Go to Cloud Messaging
2. Click "Send test message"
3. Enter FCM token
4. Send notification

### 3. Test Scheduled Function

```bash
# Trigger manually via HTTP (if manualExpiryAlerts is deployed)
curl -X POST https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/manualExpiryAlerts
```

## Part 4: Notification Types

Currently implemented:
- **pantry_expiry**: Alerts for items expiring within 3 days

Future notification types:
- **recipe_suggestion**: New recipe recommendations
- **pantry_low_stock**: Items running low
- **recipe_favorited**: Someone favorited your recipe

## Part 5: Customization

### Change Notification Schedule

Edit `functions/index.js`:

```javascript
exports.sendExpiryAlerts = functions.pubsub
  .schedule('0 9 * * *') // Change this cron expression
  .timeZone('UTC')
  .onRun(async (context) => {
    // ...
  });
```

Cron expression examples:
- `0 9 * * *` - Every day at 9:00 AM UTC
- `0 9 * * 1` - Every Monday at 9:00 AM UTC
- `0 */6 * * *` - Every 6 hours
- `*/30 * * * *` - Every 30 minutes (for testing)

### Customize Notification Content

Edit the notification message in `functions/index.js`:

```javascript
const message = {
  token: fcmToken,
  notification: {
    title: 'Your Custom Title',
    body: 'Your Custom Body',
  },
  // ...
};
```

## Troubleshooting

### Notifications not received

1. Check FCM token is saved in Firestore
2. Verify notification permissions are granted
3. Check device notification settings
4. Review Firebase Console > Cloud Messaging logs

### Cloud Function errors

1. Check Firebase Console > Functions > Logs
2. Verify Firestore security rules allow function access
3. Ensure FCM tokens are valid (invalid tokens are auto-removed)

### Android notifications not showing

1. Verify notification channel is created
2. Check Android notification settings for the app
3. Ensure app is not in battery optimization mode

### iOS notifications not working

1. Verify APNs certificates are configured in Firebase Console
2. Check iOS notification permissions
3. Ensure device is registered for remote notifications

## Security Notes

1. **FCM Tokens**: Store securely, invalidate on logout
2. **Cloud Functions**: Add authentication for manual triggers in production
3. **User Privacy**: Only send notifications users have opted into
4. **Rate Limiting**: Implement to prevent abuse

## Resources

- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [Cloud Functions for Firebase](https://firebase.google.com/docs/functions)
- [Flutter FCM Plugin](https://pub.dev/packages/firebase_messaging)
- [Cron Expression Guide](https://crontab.guru/)

