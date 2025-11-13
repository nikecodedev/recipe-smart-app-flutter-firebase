import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../core/utils/logger.dart';

/// Top-level function for handling background messages
/// Must be a top-level function, not a class method
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  Logger.info('Background message handler: ${message.messageId}', 'FCMService');
  
  // Handle background message
  // Note: This runs in a separate isolate, so you can't use UI code here
  if (kDebugMode) {
    print('Handling background message: ${message.messageId}');
    print('Message data: ${message.data}');
    print('Message notification: ${message.notification?.title}');
  }
}

/// Firebase Cloud Messaging Service
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _fcmToken;

  /// Get FCM token
  String? get fcmToken => _fcmToken;

  /// Initialize FCM service
  Future<void> initialize() async {
    try {
      print('Initializing FCM service...');
      
      // Request notification permissions
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('Notification permission status: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        Logger.success('User granted notification permission', 'FCMService');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        Logger.info('User granted provisional notification permission', 'FCMService');
      } else {
        Logger.warning('User declined or has not accepted notification permission', 'FCMService');
        print('WARNING: Notification permission not granted. Status: ${settings.authorizationStatus}');
      }

      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        Logger.success('FCM Token obtained: ${_fcmToken!.substring(0, 20)}...', 'FCMService');
        print('FCM Token: ${_fcmToken!.substring(0, 30)}...');
      } else {
        print('WARNING: FCM token is null');
      }

      // Set up notification channel for Android (if needed)
      // This is handled automatically by Firebase, but we can configure it here if needed

      // Note: Foreground messages are handled by NotificationNotifier
      // to avoid duplicate listeners

      Logger.success('FCM Service initialized successfully', 'FCMService');
      print('FCM Service initialization complete');
    } catch (e, stackTrace) {
      Logger.error('Failed to initialize FCM service', e, stackTrace, 'FCMService');
      print('ERROR: Failed to initialize FCM service: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get stream of foreground messages
  /// Note: In newer versions, this is a top-level function, not an instance method
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  /// Get stream of messages that opened the app
  /// Note: In newer versions, this is a top-level function, not an instance method
  Stream<RemoteMessage> get onMessageOpenedApp => FirebaseMessaging.onMessageOpenedApp;

  /// Get initial message if app was opened from notification
  Future<RemoteMessage?> getInitialMessage() async {
    return await _firebaseMessaging.getInitialMessage();
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      Logger.success('Subscribed to topic: $topic', 'FCMService');
    } catch (e) {
      Logger.error('Failed to subscribe to topic: $topic', e, null, 'FCMService');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      Logger.success('Unsubscribed from topic: $topic', 'FCMService');
    } catch (e) {
      Logger.error('Failed to unsubscribe from topic: $topic', e, null, 'FCMService');
    }
  }

  /// Save FCM token to user's Firestore document
  Future<void> saveTokenToFirestore(String userId) async {
    if (_fcmToken == null) {
      Logger.warning('FCM token is null, cannot save to Firestore', 'FCMService');
      return;
    }

    try {
      // This will be implemented in FirestoreService
      // await firestoreService.updateUserFCMToken(userId, _fcmToken!);
      Logger.info('FCM token saved to Firestore for user: $userId', 'FCMService');
    } catch (e) {
      Logger.error('Failed to save FCM token to Firestore', e, null, 'FCMService');
    }
  }
}

