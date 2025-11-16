import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/config/firebase_config.dart';
import '../../core/utils/logger.dart';

/// Firebase Authentication Service
/// Handles user authentication operations
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseConfig.auth;
  
  // Initialize GoogleSignIn with client ID for web
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // For web, client ID is read from meta tag in index.html
    // For Android/iOS, it's configured in Firebase Console
    scopes: ['email', 'profile'],
  );

  /// Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  /// Get current user ID
  String? get currentUserId => currentUser?.uid;

  /// Register with email and password
  Future<UserCredential> registerWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await userCredential.user?.updateDisplayName(displayName);
      }

      // Send email verification
      final user = userCredential.user;
      if (user != null && user.email != null) {
        // Wait a moment for Firebase to fully process the user creation
        await Future.delayed(const Duration(milliseconds: 1000));
        
        // Reload user to ensure we have the latest data
        try {
          await user.reload();
        } catch (e) {
          Logger.warning('Failed to reload user, continuing anyway', 'FirebaseAuthService');
        }
        
        Logger.info('Sending verification email to: ${user.email}', 'FirebaseAuthService');
        
        // Send email verification - use simple method (most reliable, no redirect URL needed)
        try {
          await user.sendEmailVerification();
          Logger.success('Verification email sent successfully to ${user.email}', 'FirebaseAuthService');
        } catch (e) {
          // Log the full error for debugging
          Logger.error('Failed to send verification email', e, null, 'FirebaseAuthService');
          Logger.error('Error type: ${e.runtimeType}, Error message: ${e.toString()}', null, null, 'FirebaseAuthService');
          
          // Check if it's a FirebaseAuthException for better error handling
          if (e is FirebaseAuthException) {
            final errorCode = e.code;
            final errorMessage = e.message ?? e.toString();
            Logger.error('Firebase Auth Error Code: $errorCode, Message: $errorMessage', null, null, 'FirebaseAuthService');
            
            // Re-throw with a user-friendly message
            throw Exception('Failed to send verification email: ${_handleAuthException(e)}');
          } else {
            // Re-throw with the original error message
            throw Exception('Failed to send verification email: ${e.toString()}');
          }
        }
      } else {
        Logger.warning('User or email is null, cannot send verification email', 'FirebaseAuthService');
        throw Exception('User email is null, cannot send verification email');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled by user');
      }

      // Obtain auth details from request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('Failed to get Google authentication token. Please try again.');
      }

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credential
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // Provide more user-friendly error messages
      final errorMessage = e.toString();
      if (errorMessage.contains('ClientID not set')) {
        throw Exception('Google Sign-In is not properly configured. Please contact support.');
      } else if (errorMessage.contains('cancelled')) {
        throw Exception('Google sign-in was cancelled');
      } else {
        throw Exception('Google sign-in failed. Please try again.');
      }
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = currentUser;
      if (user == null || user.email == null) {
        throw Exception('No user logged in');
      }

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }

      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      await user.reload();
    } catch (e) {
      throw Exception('Profile update failed: $e');
    }
  }

  /// Delete user account
  Future<void> deleteAccount(String password) async {
    try {
      final user = currentUser;
      if (user == null || user.email == null) {
        throw Exception('No user logged in');
      }

      // Re-authenticate before deletion
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Delete user account
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      if (user.email == null) {
        throw Exception('User email is null');
      }

      if (!user.emailVerified) {
        Logger.info('Sending verification email to: ${user.email}', 'FirebaseAuthService');
        
        // Send email verification - use simple method (most reliable)
        try {
          await user.sendEmailVerification();
          Logger.success('Verification email sent successfully to ${user.email}', 'FirebaseAuthService');
        } catch (e) {
          // Log the full error for debugging
          Logger.error('Failed to send verification email', e, null, 'FirebaseAuthService');
          Logger.error('Error type: ${e.runtimeType}, Error message: ${e.toString()}', null, null, 'FirebaseAuthService');
          
          // Check if it's a FirebaseAuthException for better error handling
          if (e is FirebaseAuthException) {
            final errorCode = e.code;
            final errorMessage = e.message ?? e.toString();
            Logger.error('Firebase Auth Error Code: $errorCode, Message: $errorMessage', null, null, 'FirebaseAuthService');
            
            // Re-throw with a user-friendly message
            throw Exception('Failed to send verification email: ${_handleAuthException(e)}');
          } else {
            // Re-throw with the original error message
            throw Exception('Failed to send verification email: ${e.toString()}');
          }
        }
      } else {
        Logger.info('Email already verified, no need to send verification email', 'FirebaseAuthService');
      }
    } catch (e) {
      Logger.error('Email verification failed', e, null, 'FirebaseAuthService');
      throw Exception('Email verification failed: $e');
    }
  }

  /// Get email verification redirect URL for web
  String _getEmailVerificationRedirectUrl() {
    if (kIsWeb) {
      try {
        // For web, use the current origin with a simple path
        // Firebase will redirect here after verification
        final origin = Uri.base.origin;
        // Use a simple path that will be handled by the router
        return '$origin/#/home';
      } catch (e) {
        // Fallback: return empty to use default Firebase behavior
        return '';
      }
    }
    // For non-web platforms, return empty string (Firebase will handle it)
    return '';
  }

  /// Check if email is verified
  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  /// Reload user data
  Future<void> reloadUser() async {
    await currentUser?.reload();
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak. Please use a stronger password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a few minutes and try again.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      case 'unauthorized-domain':
        return 'This email domain is not allowed. Please contact support or use a different email address.';
      case 'invalid-continue-uri':
      case 'unauthorized-continue-uri':
        return 'Email verification redirect URL is not authorized. Please contact support.';
      default:
        // Check if error message contains domain-related keywords
        final message = e.message ?? '';
        if (message.toLowerCase().contains('domain') || 
            message.toLowerCase().contains('allowlist') ||
            message.toLowerCase().contains('not allowlisted')) {
          return 'This email domain is not allowed. Please contact support or use a different email address.';
        }
        return message.isNotEmpty ? message : 'An authentication error occurred.';
    }
  }
}

