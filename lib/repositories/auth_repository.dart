import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth/firebase_auth_service.dart';
import '../services/user/user_service.dart';
import '../services/storage/local_storage_service.dart';
import '../models/user_model.dart';
import '../core/utils/logger.dart';

/// Repository for authentication operations
/// Combines Firebase Auth and Firestore user profiles
class AuthRepository {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final UserService _userService = UserService();

  /// Get current Firebase user
  User? get currentUser => _authService.currentUser;

  /// Get current user ID
  String? get currentUserId => _authService.currentUserId;

  /// Check if user is logged in
  bool get isLoggedIn => _authService.isLoggedIn;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  /// Register with email and password
  Future<UserModel> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      Logger.info('Registering user: $email', 'AuthRepository');

      // Create Firebase Auth account
      final userCredential = await _authService.registerWithEmailPassword(
        email: email,
        password: password,
        displayName: displayName,
      );

      final user = userCredential.user!;

      // Create Firestore profile
      await _userService.createUserProfile(
        userId: user.uid,
        email: email,
        displayName: displayName,
        photoURL: user.photoURL,
      );

      // Save to local storage
      await LocalStorageService.saveUserData(
        userId: user.uid,
        email: email,
        displayName: displayName,
      );

      // Get the created profile
      final userModel = await _userService.getUserProfile(user.uid);

      Logger.success('User registered successfully: $email', 'AuthRepository');

      return userModel!;
    } catch (e) {
      Logger.error('Registration failed', e, null, 'AuthRepository');
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      Logger.info('Signing in user: $email', 'AuthRepository');

      // Sign in with Firebase Auth
      final userCredential = await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user!;

      // Get or create Firestore profile
      UserModel? userModel = await _userService.getUserProfile(user.uid);

      if (userModel == null) {
        // Profile doesn't exist, create it
        await _userService.createUserProfile(
          userId: user.uid,
          email: user.email!,
          displayName: user.displayName ?? email.split('@')[0],
          photoURL: user.photoURL,
        );
        userModel = await _userService.getUserProfile(user.uid);
      }

      // Save to local storage
      await LocalStorageService.saveUserData(
        userId: user.uid,
        email: user.email!,
        displayName: userModel!.displayName,
      );

      Logger.success('User signed in successfully: $email', 'AuthRepository');

      return userModel;
    } catch (e) {
      Logger.error('Sign in failed', e, null, 'AuthRepository');
      rethrow;
    }
  }

  /// Sign in with Google
  Future<UserModel> signInWithGoogle() async {
    try {
      Logger.info('Signing in with Google', 'AuthRepository');

      // Sign in with Google
      final userCredential = await _authService.signInWithGoogle();
      final user = userCredential.user!;

      // Get or create Firestore profile
      UserModel? userModel = await _userService.getUserProfile(user.uid);

      if (userModel == null) {
        // First time sign in, create profile
        await _userService.createUserProfile(
          userId: user.uid,
          email: user.email!,
          displayName: user.displayName ?? user.email!.split('@')[0],
          photoURL: user.photoURL,
        );
        userModel = await _userService.getUserProfile(user.uid);
      }

      // Save to local storage
      await LocalStorageService.saveUserData(
        userId: user.uid,
        email: user.email!,
        displayName: userModel!.displayName,
      );

      Logger.success(
          'User signed in with Google: ${user.email}', 'AuthRepository');

      return userModel;
    } catch (e) {
      Logger.error('Google sign in failed', e, null, 'AuthRepository');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      Logger.info('Signing out user', 'AuthRepository');

      await _authService.signOut();
      await LocalStorageService.clearUserData();

      Logger.success('User signed out successfully', 'AuthRepository');
    } catch (e) {
      Logger.error('Sign out failed', e, null, 'AuthRepository');
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      Logger.info('Sending password reset email to: $email', 'AuthRepository');

      await _authService.sendPasswordResetEmail(email);

      Logger.success(
          'Password reset email sent to: $email', 'AuthRepository');
    } catch (e) {
      Logger.error(
          'Failed to send password reset email', e, null, 'AuthRepository');
      rethrow;
    }
  }

  /// Get current user profile
  Future<UserModel?> getCurrentUserProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;

    return await _userService.getUserProfile(userId);
  }

  /// Stream current user profile
  Stream<UserModel?> streamCurrentUserProfile() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value(null);
    }

    return _userService.streamUserProfile(userId);
  }

  /// Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
    UserPreferences? preferences,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('No user logged in');
    }

    try {
      // Update Firestore profile
      await _userService.updateUserProfile(
        userId: userId,
        displayName: displayName,
        photoURL: photoURL,
        preferences: preferences,
      );

      // Update Firebase Auth profile
      if (displayName != null || photoURL != null) {
        await _authService.updateProfile(
          displayName: displayName,
          photoURL: photoURL,
        );
      }

      // Update local storage
      if (displayName != null) {
        await LocalStorageService.setString(
          LocalStorageService.keyUserName,
          displayName,
        );
      }

      Logger.success('User profile updated', 'AuthRepository');
    } catch (e) {
      Logger.error('Failed to update profile', e, null, 'AuthRepository');
      rethrow;
    }
  }

  /// Delete account
  Future<void> deleteAccount(String password) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('No user logged in');
    }

    try {
      // Delete Firestore profile
      await _userService.deleteUserProfile(userId);

      // Delete Firebase Auth account
      await _authService.deleteAccount(password);

      // Clear local storage
      await LocalStorageService.clearUserData();

      Logger.success('User account deleted', 'AuthRepository');
    } catch (e) {
      Logger.error('Failed to delete account', e, null, 'AuthRepository');
      rethrow;
    }
  }
}

