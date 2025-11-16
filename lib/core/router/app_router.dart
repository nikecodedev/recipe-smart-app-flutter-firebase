import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../services/auth/firebase_auth_service.dart';
import '../../repositories/auth_repository.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/pantry/presentation/screens/pantry_list_screen.dart';
import '../../features/pantry/presentation/screens/pantry_edit_screen.dart';
import '../../models/pantry_item_model.dart';
import '../../features/recipes/presentation/screens/recipe_list_screen.dart';
import '../../features/recipes/presentation/screens/recipe_detail_screen.dart';
import '../../features/recipes/presentation/screens/recipe_add_screen.dart';
import '../../models/recipe_model.dart';
import '../../features/shopping/presentation/screens/shopping_list_screen.dart';
import '../../features/shopping/presentation/screens/shopping_lists_screen.dart';
import '../../models/shopping_list_model.dart';
import '../../features/feedback/presentation/screens/feedback_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_recipes_screen.dart';
import '../../features/admin/presentation/screens/admin_users_screen.dart';
import '../../features/admin/presentation/screens/admin_categories_screen.dart';
import '../../features/admin/presentation/screens/admin_feedback_screen.dart';
import 'admin_guard.dart';

/// Route names
class Routes {
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String emailVerification = '/email-verification';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String pantry = '/pantry';
  static const String pantryEdit = '/pantry/edit';
  static const String recipes = '/recipes';
  static const String recipeDetail = '/recipes/detail';
  static const String recipeAdd = '/recipes/add';
  static const String recipeEdit = '/recipes/edit';
  static const String shoppingList = '/shopping-list';
  static const String shoppingLists = '/shopping-lists';
  static const String feedback = '/feedback';
  static const String adminDashboard = '/admin';
  static const String adminRecipes = '/admin/recipes';
  static const String adminUsers = '/admin/users';
  static const String adminCategories = '/admin/categories';
  static const String adminFeedback = '/admin/feedback';
}

/// GoRouter provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final authService = FirebaseAuthService();
  final authRepository = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: Routes.login,
    redirect: (context, state) async {
      // Check both provider state and Firebase Auth directly to handle timing issues
      final authStateValue = authState.value;
      final firebaseUser = authService.currentUser;
      final isLoggedIn = authStateValue != null || firebaseUser != null;
      
      final isGoingToLogin = state.matchedLocation == Routes.login;
      final isGoingToRegister = state.matchedLocation == Routes.register;
      final isGoingToForgotPassword =
          state.matchedLocation == Routes.forgotPassword;
      final isGoingToEmailVerification =
          state.matchedLocation == Routes.emailVerification;

      // Always allow navigation to email verification screen
      // This is needed right after registration when authState might not be updated yet
      if (isGoingToEmailVerification) {
        // Allow navigation - user might have just registered
        // The screen itself will handle checking if user is logged in
        return null;
      }

      // If not logged in and not going to auth screens, redirect to login
      if (!isLoggedIn &&
          !isGoingToLogin &&
          !isGoingToRegister &&
          !isGoingToForgotPassword &&
          !isGoingToEmailVerification) {
        return Routes.login;
      }

      // If logged in, check email verification
      if (isLoggedIn) {
        // Always allow navigation to email verification screen (needed after registration)
        if (isGoingToEmailVerification) {
          return null; // Allow navigation
        }
        
        // Reload user to get latest verification status (important when coming from email link)
        try {
          await authRepository.reloadUser();
        } catch (e) {
          // Ignore errors, continue with current state
        }
        
        final isEmailVerified = authRepository.isEmailVerified;
        
        // If email is verified, redirect to home if on auth screens
        if (isEmailVerified) {
          if (isGoingToLogin || isGoingToForgotPassword) {
            return Routes.home;
          }
          // Allow staying on register screen
        } else {
          // If email is not verified
          // Allow staying on register screen (for navigation to email verification)
          if (isGoingToRegister) {
            return null; // Allow navigation to register screen
          }
          // Allow access to login and forgot password for sign out
          if (isGoingToLogin || isGoingToForgotPassword) {
            return null; // Allow navigation
          }
          // For other pages, redirect to verification screen
          final user = authStateValue ?? firebaseUser;
          if (user?.email != null) {
            return '${Routes.emailVerification}?email=${Uri.encodeComponent(user!.email!)}';
          }
        }
      }

      // No redirect needed
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.login,
        name: 'login',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: Routes.register,
        name: 'register',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        name: 'forgot-password',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: Routes.emailVerification,
        name: 'email-verification',
        pageBuilder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return MaterialPage(
            key: state.pageKey,
            child: EmailVerificationScreen(email: email),
          );
        },
      ),
      GoRoute(
        path: Routes.home,
        name: 'home',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: Routes.profile,
        name: 'profile',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ProfileScreen(),
        ),
      ),
      GoRoute(
        path: Routes.pantry,
        name: 'pantry',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const PantryListScreen(),
        ),
      ),
      GoRoute(
        path: Routes.pantryEdit,
        name: 'pantry-edit',
        pageBuilder: (context, state) {
          final extra = state.extra as PantryItem?;
          return MaterialPage(
            key: state.pageKey,
            child: PantryEditScreen(item: extra),
          );
        },
      ),
      GoRoute(
        path: Routes.recipes,
        name: 'recipes',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const RecipeListScreen(),
        ),
      ),
      GoRoute(
        path: Routes.recipeDetail,
        name: 'recipe-detail',
        pageBuilder: (context, state) {
          final extra = state.extra as Recipe;
          return MaterialPage(
            key: state.pageKey,
            child: RecipeDetailScreen(recipe: extra),
          );
        },
      ),
      GoRoute(
        path: Routes.recipeAdd,
        name: 'recipe-add',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const RecipeAddScreen(),
        ),
      ),
      GoRoute(
        path: Routes.recipeEdit,
        name: 'recipe-edit',
        pageBuilder: (context, state) {
          final extra = state.extra as Recipe;
          return MaterialPage(
            key: state.pageKey,
            child: RecipeAddScreen(recipe: extra),
          );
        },
      ),
      GoRoute(
        path: Routes.shoppingLists,
        name: 'shopping-lists',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ShoppingListsScreen(),
        ),
      ),
      GoRoute(
        path: Routes.shoppingList,
        name: 'shopping-list',
        pageBuilder: (context, state) {
          final extra = state.extra as ShoppingList;
          return MaterialPage(
            key: state.pageKey,
            child: ShoppingListScreen(shoppingList: extra),
          );
        },
      ),
      GoRoute(
        path: Routes.feedback,
        name: 'feedback',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const FeedbackScreen(),
        ),
      ),
      // Admin Routes (with access control)
      GoRoute(
        path: Routes.adminDashboard,
        name: 'admin-dashboard',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: AdminGuard.buildAdminRoute(
            context,
            state,
            const AdminDashboardScreen(),
          ),
        ),
      ),
      GoRoute(
        path: Routes.adminRecipes,
        name: 'admin-recipes',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: AdminGuard.buildAdminRoute(
            context,
            state,
            const AdminRecipesScreen(),
          ),
        ),
      ),
      GoRoute(
        path: Routes.adminUsers,
        name: 'admin-users',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: AdminGuard.buildAdminRoute(
            context,
            state,
            const AdminUsersScreen(),
          ),
        ),
      ),
      GoRoute(
        path: Routes.adminCategories,
        name: 'admin-categories',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: AdminGuard.buildAdminRoute(
            context,
            state,
            const AdminCategoriesScreen(),
          ),
        ),
      ),
      GoRoute(
        path: Routes.adminFeedback,
        name: 'admin-feedback',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: AdminGuard.buildAdminRoute(
            context,
            state,
            const AdminFeedbackScreen(),
          ),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
  );
});

