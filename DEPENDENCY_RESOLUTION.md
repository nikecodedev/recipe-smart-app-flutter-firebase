# Dependency Resolution Notes

## Issue Encountered

During initial setup, we encountered version conflicts with some packages.

### Problems & Solutions

#### 1. ❌ firebase_functions Package Not Found
**Error**: `firebase_functions ^5.2.3 doesn't match any versions`

**Cause**: Incorrect package name used.

**Solution**: The correct package name is `cloud_functions`, not `firebase_functions`.

**Decision**: Removed for now as it's optional for MVP. Can be added later when needed.

#### 2. ❌ intl Version Conflict
**Error**: `form_builder_validators` requires `intl ^0.19.0` but Flutter requires `intl 0.20.2`

**Cause**: Version incompatibility between `form_builder_validators` and Flutter's built-in `flutter_localizations`.

**Solution**: Removed `flutter_form_builder` and `form_builder_validators` packages.

**Decision**: These are optional packages for enhanced forms. We'll use the built-in `Validators` utility class created in `lib/core/utils/validators.dart` instead.

---

## Final Working Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  cupertino_icons: ^1.0.8

  # Firebase Core Services
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.0
  cloud_firestore: ^5.4.0
  firebase_storage: ^12.3.0
  
  # Google Sign In
  google_sign_in: ^6.2.1
  
  # State Management
  flutter_riverpod: ^2.5.1
  
  # Navigation
  go_router: ^14.2.7
  
  # Storage
  shared_preferences: ^2.3.2
  flutter_secure_storage: ^9.2.2
  
  # HTTP & API
  dio: ^5.4.3
  
  # UI
  google_fonts: ^6.2.1
  cached_network_image: ^3.4.1
  shimmer: ^3.0.0
  
  # Utils
  intl: ^0.20.0
  uuid: ^4.5.0
```

---

## Packages Removed (Optional - Can Add Later)

1. **cloud_functions** - For Firebase Cloud Functions integration
   - Can be added when backend functions are needed
   - Package name: `cloud_functions: ^5.1.3`

2. **flutter_form_builder** & **form_builder_validators**
   - Enhanced form handling with validation
   - Removed due to intl version conflicts
   - Alternative: Use custom `Validators` class in `lib/core/utils/validators.dart`

---

## Verification Steps

✅ All dependencies installed successfully:
```bash
flutter pub get
```

✅ No linter errors:
```bash
flutter analyze
# Result: No issues found!
```

✅ Ready to run:
```bash
flutter run
```

---

## Adding Removed Packages Later

### If you need Cloud Functions:

```yaml
cloud_functions: ^5.1.3
```

Then in code:
```dart
import 'package:cloud_functions/cloud_functions.dart';

final functions = FirebaseFunctions.instance;
final callable = functions.httpsCallable('functionName');
final result = await callable.call();
```

### If you need Form Builder:

Wait for compatible versions or use alternative form packages:
- `reactive_forms: ^17.0.0` (modern alternative)
- Or stick with built-in Form widgets + custom Validators class

---

## Notes for Production

When deploying to production, consider:

1. **Update to latest compatible versions**:
   ```bash
   flutter pub upgrade --major-versions
   ```

2. **Check for newer versions**:
   ```bash
   flutter pub outdated
   ```

3. **Test thoroughly** after any dependency updates

4. **Pin versions** in production for stability

---

**Status**: ✅ All dependencies resolved and working correctly.

**Last Updated**: November 11, 2025

