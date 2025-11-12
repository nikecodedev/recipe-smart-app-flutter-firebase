import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
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

/// Route names
class Routes {
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
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
}

/// GoRouter provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: Routes.login,
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isGoingToLogin = state.matchedLocation == Routes.login;
      final isGoingToRegister = state.matchedLocation == Routes.register;
      final isGoingToForgotPassword =
          state.matchedLocation == Routes.forgotPassword;

      // If not logged in and not going to auth screens, redirect to login
      if (!isLoggedIn &&
          !isGoingToLogin &&
          !isGoingToRegister &&
          !isGoingToForgotPassword) {
        return Routes.login;
      }

      // If logged in and going to auth screens, redirect to home
      if (isLoggedIn &&
          (isGoingToLogin || isGoingToRegister || isGoingToForgotPassword)) {
        return Routes.home;
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
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
  );
});

