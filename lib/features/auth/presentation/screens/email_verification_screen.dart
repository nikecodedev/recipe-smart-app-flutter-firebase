import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/utils/logger.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/auth/firebase_auth_service.dart';
import '../../../../core/config/firebase_config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  
  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  bool _isLoading = false;
  bool _isResending = false;
  bool _isVerified = false;
  final FirebaseAuthService _authService = FirebaseAuthService();

  @override
  void initState() {
    super.initState();
    // Handle email verification link if app opened from email (web only)
    // Also check initial verification status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialVerificationStatus();
      _handleEmailVerificationLink();
    });
  }

  Future<void> _checkInitialVerificationStatus() async {
    try {
      await _authService.reloadUser();
      if (mounted) {
        setState(() {
          _isVerified = _authService.isEmailVerified;
        });
      }
    } catch (e) {
      Logger.error('Error checking initial verification status', e, null, 'EmailVerificationScreen');
    }
  }

  Future<void> _handleResendEmail() async {
    setState(() => _isResending = true);

    try {
      await ref.read(authControllerProvider.notifier).resendVerificationEmail();

      if (mounted) {
        Logger.success('Verification email resent', 'EmailVerificationScreen');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Please check your inbox.'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('Exception: ')) {
          errorMessage = errorMessage.replaceFirst('Exception: ', '');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
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
        Logger.info('Email verification link detected', 'EmailVerificationScreen');
        
        try {
          // Apply the action code directly to verify the email
          final auth = FirebaseConfig.auth;
          
          // Apply the verification code using FirebaseAuth
          await auth.applyActionCode(oobCode);
          Logger.success('Email verified via action code', 'EmailVerificationScreen');
          
          // Reload user to get updated verification status
          final currentUser = auth.currentUser;
          if (currentUser != null) {
            await currentUser.reload();
          }
          
          // Wait a moment for the state to update
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Check verification status and update UI
          await _authService.reloadUser();
          if (mounted) {
            setState(() {
              _isVerified = _authService.isEmailVerified;
            });
            if (_isVerified) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Email verified successfully! You can now access the app.'),
                  backgroundColor: AppColors.success,
                  duration: Duration(seconds: 4),
                ),
              );
            }
          }
        } catch (e) {
          Logger.error('Error applying action code', e, null, 'EmailVerificationScreen');
          // Even if applying fails, check if email is already verified
          await Future.delayed(const Duration(milliseconds: 500));
          await _authService.reloadUser();
          
          if (_authService.isEmailVerified && mounted) {
            Logger.success('Email already verified', 'EmailVerificationScreen');
            setState(() {
              _isVerified = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Email verified successfully! You can now access the app.'),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      }
    } catch (e) {
      Logger.error('Error handling email verification link', e, null, 'EmailVerificationScreen');
    }
  }

  Future<void> _handleCheckVerification() async {
    setState(() => _isLoading = true);

    try {
      // First, check if there's a verification link in the URL (user might have clicked it)
      if (kIsWeb) {
        final uri = Uri.base;
        final mode = uri.queryParameters['mode'];
        final oobCode = uri.queryParameters['oobCode'];
        
        if (mode == 'verifyEmail' && oobCode != null) {
          // User clicked the link, apply the action code
          try {
            final auth = FirebaseConfig.auth;
            await auth.applyActionCode(oobCode);
            Logger.success('Email verified via action code from button', 'EmailVerificationScreen');
            
            // Reload user
            final currentUser = auth.currentUser;
            if (currentUser != null) {
              await currentUser.reload();
            }
            await Future.delayed(const Duration(milliseconds: 500));
          } catch (e) {
            Logger.error('Error applying action code from button', e, null, 'EmailVerificationScreen');
          }
        }
      }
      
      // Reload user data to get latest verification status
      await _authService.reloadUser();
      final isVerified = _authService.isEmailVerified;

      if (mounted) {
        setState(() {
          _isVerified = isVerified;
        });
        if (isVerified) {
          Logger.success('Email verified', 'EmailVerificationScreen');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verified successfully! You can now access the app.'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email not verified yet. Please check your inbox and click the verification link.'),
              backgroundColor: AppColors.warning,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking verification: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await ref.read(authControllerProvider.notifier).signOut();
      if (mounted) {
        context.go(Routes.login);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : () => _handleSignOut(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Icon
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.email_outlined,
                    size: 64,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Title
              const Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Description
              Text(
                'We\'ve sent a verification link to\n${widget.email}',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                'Please check your inbox and click the verification link to activate your account.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Show different UI based on verification status
              if (_isVerified) ...[
                // Email is verified - show success and go to home button
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Email Verified!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your email has been verified. You can now access all features.',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Go to Home',
                  onPressed: () => context.go(Routes.home),
                  icon: Icons.home,
                ),
              ] else ...[
                // Email not verified - show verification buttons
                CustomButton(
                  text: 'I\'ve Verified My Email',
                  onPressed: _isLoading ? null : _handleCheckVerification,
                  isLoading: _isLoading,
                  icon: Icons.check_circle_outline,
                ),
                const SizedBox(height: 16),
                CustomOutlinedButton(
                  text: _isResending ? 'Sending...' : 'Resend Verification Email',
                  onPressed: _isResending ? null : _handleResendEmail,
                  icon: Icons.refresh,
                ),
              ],

              const SizedBox(height: 24),

              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Didn\'t receive the email? Check your spam folder or try resending.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Sign Out Option
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : _handleSignOut,
                  child: Text(
                    'Sign Out',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

