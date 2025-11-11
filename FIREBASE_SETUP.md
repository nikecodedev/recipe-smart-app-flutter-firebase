# Firebase Setup Guide

This guide will help you configure Firebase for your Flutter project.

## Prerequisites

- Flutter SDK installed (>=3.9.2)
- Firebase account (create one at [firebase.google.com](https://firebase.google.com))
- Node.js installed (for Firebase CLI)
- Dart SDK (>=3.9.2)

## Step 1: Install Firebase CLI

```bash
npm install -g firebase-tools
```

## Step 2: Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

## Step 3: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name (e.g., "smart-pantry-app")
4. Enable Google Analytics (optional)
5. Click "Create project"

## Step 4: Configure Firebase for Flutter

Run the following command in your project root:

```bash
flutterfire configure
```

This will:
- Prompt you to select your Firebase project
- Ask which platforms to configure (Android, iOS, Web, macOS)
- Automatically generate `firebase_options.dart` with your credentials
- Update platform-specific configuration files

### Platform-Specific Configuration

#### Android
The FlutterFire CLI automatically updates:
- `android/app/google-services.json`
- `android/build.gradle`
- `android/app/build.gradle`

#### iOS
The FlutterFire CLI automatically updates:
- `ios/Runner/GoogleService-Info.plist`
- `ios/Runner.xcworkspace`

#### Web
Updates `web/index.html` with Firebase SDK scripts.

## Step 5: Enable Firebase Services

In the Firebase Console, enable the following services:

### 1. Authentication
1. Go to **Authentication** > **Sign-in method**
2. Enable the following providers:
   - **Email/Password** ✅
   - **Google** ✅ (for google_sign_in)
3. Add authorized domains if needed

### 2. Firestore Database
1. Go to **Firestore Database** > **Create database**
2. Choose **Start in test mode** (for development)
3. Select a location (e.g., us-central1)
4. Click **Enable**

**Security Rules (Initial - Test Mode):**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.time < timestamp.date(2025, 12, 31);
    }
  }
}
```

**Production Security Rules (Update later):**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Pantry items - user-specific
    match /pantry_items/{itemId} {
      allow read, write: if request.auth != null && 
                           resource.data.userId == request.auth.uid;
    }
    
    // Recipes - public read, authenticated write
    match /recipes/{recipeId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.userId || 
                               get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Shopping lists - user-specific
    match /shopping_lists/{listId} {
      allow read, write: if request.auth != null && 
                           resource.data.userId == request.auth.uid;
    }
    
    // Recommendations - user-specific
    match /recommendations/{recId} {
      allow read, write: if request.auth != null && 
                           resource.data.userId == request.auth.uid;
    }
  }
}
```

### 3. Storage
1. Go to **Storage** > **Get started**
2. Start in **test mode**
3. Choose a location

**Storage Rules (Initial - Test Mode):**
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.time < timestamp.date(2025, 12, 31);
    }
  }
}
```

**Production Storage Rules:**
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // User profile images
    match /users/{userId}/profile/{imageId} {
      allow read: if true;
      allow write: if request.auth.uid == userId && 
                     request.resource.size < 5 * 1024 * 1024 && // 5MB max
                     request.resource.contentType.matches('image/.*');
    }
    
    // Recipe images
    match /recipes/{recipeId}/{imageId} {
      allow read: if true;
      allow write: if request.auth != null && 
                     request.resource.size < 10 * 1024 * 1024 && // 10MB max
                     request.resource.contentType.matches('image/.*');
    }
    
    // Pantry item images
    match /pantry/{userId}/{itemId}/{imageId} {
      allow read: if request.auth.uid == userId;
      allow write: if request.auth.uid == userId && 
                     request.resource.size < 5 * 1024 * 1024 && // 5MB max
                     request.resource.contentType.matches('image/.*');
    }
  }
}
```

### 4. Cloud Functions (Optional)
1. Go to **Functions**
2. Upgrade to Blaze plan (pay-as-you-go) if needed
3. Deploy functions from `functions/` directory

## Step 6: Configure Google Sign-In (Android)

### Get SHA-1 Certificate Fingerprint

#### For Debug Build:
```bash
# Windows
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

# macOS/Linux
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

#### For Release Build:
```bash
keytool -list -v -keystore your-release-key.keystore -alias your-key-alias
```

### Add SHA-1 to Firebase:
1. Go to Firebase Console > Project Settings
2. Scroll to "Your apps" section
3. Click on Android app
4. Add SHA-1 certificate fingerprint
5. Download updated `google-services.json`
6. Replace in `android/app/google-services.json`

## Step 7: Configure Google Sign-In (iOS)

1. Open `ios/Runner/Info.plist`
2. Add your reversed client ID (found in `GoogleService-Info.plist`):

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

## Step 8: Test Firebase Connection

Run the app:

```bash
flutter pub get
flutter run
```

Check the console logs for:
```
[Firebase] Initialized successfully
```

## Step 9: Initialize Firestore Collections

You can manually create collections in Firebase Console or let the app create them on first write.

### Create Indexes (for complex queries):

Go to **Firestore** > **Indexes** and create:

1. **Pantry Items - Expiry Query**
   - Collection: `pantry_items`
   - Fields: `userId` (Ascending), `expiryDate` (Ascending)

2. **Recipes - Search Query**
   - Collection: `recipes`
   - Fields: `category` (Ascending), `createdAt` (Descending)

3. **Shopping List - Category Query**
   - Collection: `shopping_items`
   - Fields: `listId` (Ascending), `category` (Ascending), `isPurchased` (Ascending)

## Troubleshooting

### Common Issues:

1. **"FirebaseOptions not found"**
   - Run `flutterfire configure` again
   - Ensure `firebase_options.dart` exists in `lib/`

2. **"Multidex error" (Android)**
   - Add to `android/app/build.gradle`:
   ```gradle
   android {
       defaultConfig {
           multiDexEnabled true
       }
   }
   ```

3. **"Google Sign-In failed" (Android)**
   - Verify SHA-1 fingerprint is added to Firebase
   - Download latest `google-services.json`
   - Clean and rebuild: `flutter clean && flutter run`

4. **"Permission denied" on Firestore**
   - Check security rules
   - Ensure user is authenticated
   - Verify `request.auth.uid` matches document owner

## Environment Variables (Optional)

For sensitive configuration, use environment variables:

1. Create `.env` file (add to `.gitignore`):
```env
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_STORAGE_BUCKET=your_storage_bucket
```

2. Use `flutter_dotenv` package to load variables

## Next Steps

1. ✅ Firebase configured
2. ➡️ Implement authentication flow
3. ➡️ Set up Firestore data models
4. ➡️ Build feature modules

## Useful Commands

```bash
# Get Firebase project info
firebase projects:list

# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules
firebase deploy --only storage

# View Firestore data
firebase firestore:indexes

# Test security rules locally
firebase emulators:start
```

## Resources

- [FlutterFire Documentation](https://firebase.flutter.dev)
- [Firebase Console](https://console.firebase.google.com)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)

