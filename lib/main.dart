import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'services/storage/local_storage_service.dart';
import 'services/notifications/fcm_background_handler.dart';
import 'providers/notification_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';
import 'services/firestore/firestore_service.dart';
import 'core/utils/logger.dart';

void main() async {
  // Ensure Flutter binding is initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  Logger.firebase('Firebase initialized');

  // Initialize Local Storage
  await LocalStorageService.initialize();
  Logger.info('Local storage initialized', 'Main');

  // Initialize FCM background handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  Logger.info('FCM background handler registered', 'Main');

  // Run app with Riverpod
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize FCM when app starts
    // The NotificationNotifier will initialize itself when created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        // Access the notifier to trigger initialization
        // The notifier initializes FCM in its constructor
        final notifier = ref.read(notificationStateProvider.notifier);
        print('Notification notifier initialized');
        
        // Also listen for token updates when user logs in
        ref.listen(currentUserIdProvider, (previous, next) {
          if (next != null) {
            print('User logged in, saving FCM token for user: $next');
            // User logged in, ensure token is saved
            final fcmService = ref.read(fcmServiceProvider);
            if (fcmService.fcmToken != null) {
              final firestoreService = ref.read(firestoreServiceProvider);
              firestoreService.updateUserFCMToken(next, fcmService.fcmToken!).then((_) {
                print('FCM token saved successfully for user: $next');
              }).catchError((e) {
                print('Failed to save FCM token after login: $e');
              });
            } else {
              print('FCM token is null, cannot save');
            }
          }
        });
      } catch (e) {
        print('Error initializing notifications: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Smart Pantry',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
