# Smart Pantry Management App

A comprehensive Flutter application for managing your pantry, discovering recipes, and reducing food waste.

## 🚀 Features

- **👤 User Authentication**: Email/password and Google Sign-In
- **🥘 Pantry Management**: Track food items, quantities, and expiry dates
- **📖 Recipe Database**: Browse, create, and share recipes
- **🛒 Shopping Lists**: Organize your grocery shopping
- **🤖 Smart Recommendations**: AI-powered recipe suggestions based on available ingredients
- **👨‍💼 Admin Dashboard**: Manage users and approve recipes
- **📱 Cross-Platform**: Android, iOS, Web, macOS support

## 📋 Prerequisites

- Flutter SDK (>=3.9.2)
- Dart SDK (>=3.9.2)
- Firebase account
- Android Studio / Xcode (for mobile development)
- Node.js (for Firebase CLI)

## 🛠️ Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd my_first
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

Follow the detailed setup guide in [FIREBASE_SETUP.md](FIREBASE_SETUP.md)

Quick steps:
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your project
flutterfire configure
```

### 4. Run the App

```bash
# Run on connected device/emulator
flutter run

# Run on specific platform
flutter run -d chrome        # Web
flutter run -d android       # Android
flutter run -d ios           # iOS
flutter run -d macos         # macOS
```

## 📁 Project Structure

```
lib/
├── main.dart                  # App entry point
├── firebase_options.dart      # Firebase configuration
│
├── core/                      # Core utilities and config
│   ├── config/
│   │   └── firebase_config.dart
│   ├── constants/
│   │   └── firebase_constants.dart
│   ├── theme/
│   ├── router/
│   ├── utils/
│   │   ├── validators.dart
│   │   ├── formatters.dart
│   │   └── logger.dart
│   └── widgets/               # Reusable widgets
│
├── services/                  # Business logic services
│   ├── auth/
│   │   └── firebase_auth_service.dart
│   ├── storage/
│   │   ├── local_storage_service.dart
│   │   └── secure_storage_service.dart
│   ├── pantry/
│   ├── recipe/
│   ├── shopping/
│   └── recommendation/
│
├── models/                    # Data models
│   ├── user_model.dart
│   ├── pantry_item_model.dart
│   ├── recipe_model.dart
│   └── ...
│
└── features/                  # Feature modules
    ├── auth/
    ├── pantry/
    ├── recipes/
    ├── shopping_list/
    ├── recommendation/
    ├── admin/
    └── home/
```

## 🗄️ Firestore Structure

See [FIRESTORE_STRUCTURE.md](FIRESTORE_STRUCTURE.md) for complete database schema.

### Collections:
- `users` - User profiles and preferences
- `pantry_items` - User pantry inventory
- `recipes` - Recipe database
- `shopping_lists` - Shopping lists
- `shopping_items` - Individual shopping items
- `recommendations` - AI-generated recommendations
- `categories` - Item and recipe categories

## 🔑 Environment Setup

### Development

1. Update `firebase_options.dart` with your Firebase configuration
2. Run the app in debug mode:
   ```bash
   flutter run --debug
   ```

### Production

1. Configure Firebase production project
2. Update security rules in Firebase Console
3. Build release version:
   ```bash
   flutter build apk --release        # Android
   flutter build ios --release        # iOS
   flutter build web --release        # Web
   ```

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test/
```

## 📦 Dependencies

### Core
- `firebase_core` - Firebase initialization
- `firebase_auth` - Authentication
- `cloud_firestore` - Database
- `firebase_storage` - File storage
- `firebase_functions` - Cloud functions

### State Management
- `flutter_riverpod` - State management

### Navigation
- `go_router` - Declarative routing

### Storage
- `shared_preferences` - Local storage
- `flutter_secure_storage` - Secure storage

### UI
- `google_fonts` - Custom fonts
- `cached_network_image` - Image caching
- `shimmer` - Loading effects

### Utils
- `intl` - Internationalization
- `uuid` - Unique ID generation
- `dio` - HTTP client

## 🎨 Theming

The app uses Material Design 3 with custom theming. Theme configuration is located in `lib/core/theme/`.

## 🌐 Localization

Currently supports English. Additional languages can be added in `lib/l10n/`.

## 🔒 Security

- **Authentication**: Firebase Auth with email/password and Google Sign-In
- **Authorization**: Role-based access control (user/admin)
- **Data Security**: Firestore security rules protect user data
- **Secure Storage**: Sensitive data stored using FlutterSecureStorage
- **API Keys**: Keep Firebase configuration secure (use .env for sensitive data)

## 🚧 Development Roadmap

### Phase 1: Core Features ✅
- [x] Firebase integration
- [x] Project structure setup
- [x] Core services and utilities

### Phase 2: Authentication (In Progress)
- [ ] Login/Register screens
- [ ] Email verification
- [ ] Password reset
- [ ] Google Sign-In

### Phase 3: Pantry Management
- [ ] Add/Edit/Delete pantry items
- [ ] Category filtering
- [ ] Expiry tracking
- [ ] Barcode scanning

### Phase 4: Recipe System
- [ ] Recipe browsing
- [ ] Recipe creation
- [ ] Recipe search and filtering
- [ ] Recipe ratings and reviews

### Phase 5: Shopping List
- [ ] Create shopping lists
- [ ] Add items from recipes
- [ ] Mark items as purchased
- [ ] Shopping history

### Phase 6: Recommendations
- [ ] AI recipe recommendations
- [ ] Ingredient matching
- [ ] Expiry-based suggestions

### Phase 7: Admin Features
- [ ] User management
- [ ] Recipe approval
- [ ] Analytics dashboard

## 🐛 Known Issues

- None currently. Report issues in the issue tracker.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 📞 Support

For questions or issues:
- Create an issue in the repository
- Contact the development team

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Open source community

---

**Version**: 1.0.0  
**Last Updated**: November 11, 2025
