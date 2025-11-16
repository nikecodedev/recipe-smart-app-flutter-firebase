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
import 'repositories/auth_repository.dart';
import 'core/router/app_router.dart';
import 'core/utils/logger.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'core/config/firebase_config.dart';

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
        // Handle email verification link (for web)
        _handleEmailVerificationLink();
        
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

        // Listen for auth state changes to detect email verification
        ref.listen(authStateProvider, (previous, next) async {
          if (next.value != null) {
            // User is logged in, check if email was just verified
            try {
              final authRepository = ref.read(authRepositoryProvider);
              await authRepository.reloadUser();
              final isVerified = authRepository.isEmailVerified;
              
              // Check if email was just verified (was not verified before)
              final previousUser = previous?.value;
              final wasVerifiedBefore = previousUser?.emailVerified ?? false;
              
              if (isVerified && !wasVerifiedBefore) {
                // Email was just verified, navigate to home
                Logger.success('Email verified, navigating to home', 'Main');
                final router = ref.read(routerProvider);
                router.go(Routes.home);
              }
            } catch (e) {
              Logger.error('Error checking email verification', e, null, 'Main');
            }
          }
        });
      } catch (e) {
        print('Error initializing notifications: $e');
      }
    });
  }

  /// Handle email verification link when app opens from email (web only)
  Future<void> _handleEmailVerificationLink() async {
    if (!kIsWeb) return;
    
    try {
      // Check if URL contains email verification parameters (web only)
      final uri = Uri.base;
      final mode = uri.queryParameters['mode'];
      final oobCode = uri.queryParameters['oobCode'];
      
      if (mode == 'verifyEmail' && oobCode != null) {
        Logger.info('Email verification link detected in main.dart', 'Main');
        
        try {
          // Apply the action code directly to verify the email
          final auth = FirebaseConfig.auth;
          
          // Check if user is logged in
          final currentUser = auth.currentUser;
          if (currentUser == null) {
            Logger.warning('No user logged in when processing verification link', 'Main');
            // User might need to log in first, but the link should still work
            // Firebase will verify when they log in
            return;
          }
          
          // Apply the verification code using FirebaseAuth
          await auth.applyActionCode(oobCode);
          Logger.success('Email verified via action code', 'Main');
          
          // Reload user to get updated verification status
          await currentUser.reload();
          
          // Wait a moment for the state to update
          await Future.delayed(const Duration(milliseconds: 1000));
          
          // Check verification status and navigate
          final authRepository = ref.read(authRepositoryProvider);
          await authRepository.reloadUser();
          
          if (authRepository.isEmailVerified) {
            Logger.success('Email verified', 'Main');
            // Don't auto-redirect - let user stay on email verification screen
            // They can manually check verification status
          }
        } catch (e) {
          Logger.error('Error applying action code', e, null, 'Main');
          // Even if applying fails, check if email is already verified
          // (Firebase might have processed it automatically)
          await Future.delayed(const Duration(milliseconds: 1000));
          final authRepository = ref.read(authRepositoryProvider);
          await authRepository.reloadUser();
          
          if (authRepository.isEmailVerified) {
            Logger.success('Email already verified', 'Main');
            // Don't auto-redirect - let user stay on email verification screen
          } else {
            // If verification failed and user is logged in, navigate to email verification screen
            final auth = FirebaseConfig.auth;
            final currentUser = auth.currentUser;
            if (currentUser != null && currentUser.email != null) {
              Logger.info('Verification failed, navigating to email verification screen', 'Main');
              final router = ref.read(routerProvider);
              router.go('${Routes.emailVerification}?email=${Uri.encodeComponent(currentUser.email!)}');
            }
          }
        }
      }
    } catch (e) {
      Logger.error('Error handling email verification link', e, null, 'Main');
    }
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
