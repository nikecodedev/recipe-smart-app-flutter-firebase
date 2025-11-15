import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/notification_provider.dart';
import '../../../../providers/pantry_provider.dart';
import '../../../../providers/recipe_provider.dart';
import '../../../../providers/shopping_list_provider.dart';
import '../../../../widgets/notification_banner.dart';
import '../../../../core/utils/logger.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final pantryItemsAsync = ref.watch(pantryItemsStreamProvider);
    final recipesAsync = ref.watch(userRecipesStreamProvider);
    final shoppingListsAsync = ref.watch(shoppingListsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Image.asset(
              'logo/logococinaentucasa.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            const Text(
              'Cocina en tu Casa',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final notificationState = ref.watch(notificationStateProvider);
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    onPressed: () {
                      // TODO: Show notification list
                    },
                  ),
                  if (notificationState.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          notificationState.unreadCount > 9
                              ? '9+'
                              : '${notificationState.unreadCount}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () {
              context.push(Routes.profile);
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, ref, userAsync),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(pantryItemsStreamProvider);
              ref.invalidate(userRecipesStreamProvider);
              ref.invalidate(shoppingListsStreamProvider);
            },
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                // Header Section with Gradient
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primaryDark,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    child: userAsync.when(
                      data: (user) {
                        if (user == null) {
                          return const Column(
                            children: [
                              Text(
                                'Welcome!',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          );
                        }

                        final hour = DateTime.now().hour;
                        String greeting;
                        if (hour < 12) {
                          greeting = 'Good Morning';
                        } else if (hour < 17) {
                          greeting = 'Good Afternoon';
                        } else {
                          greeting = 'Good Evening';
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greeting,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              (user.displayName.isNotEmpty 
                                  ? user.displayName 
                                  : (user.email.isNotEmpty ? user.email : 'User')),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    user.isAdmin ? 'Admin' : 'User',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const SizedBox(
                        height: 100,
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                      error: (error, _) => Text(
                        'Error: $error',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),

                // Stats Cards
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Pantry Items',
                            pantryItemsAsync.when(
                              data: (items) => items.length.toString(),
                              loading: () => '...',
                              error: (_, __) => '0',
                            ),
                            Icons.kitchen_outlined,
                            AppColors.primary,
                            () => context.push(Routes.pantry),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Recipes',
                            recipesAsync.when(
                              data: (recipes) => recipes.length.toString(),
                              loading: () => '...',
                              error: (_, __) => '0',
                            ),
                            Icons.restaurant_menu_outlined,
                            AppColors.secondary,
                            () => context.push(Routes.recipes),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Shopping Lists',
                            shoppingListsAsync.when(
                              data: (lists) => lists.length.toString(),
                              loading: () => '...',
                              error: (_, __) => '0',
                            ),
                            Icons.shopping_cart_outlined,
                            AppColors.warning,
                            () => context.push(Routes.shoppingLists),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Quick Actions
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickActionCard(
                                context,
                                'Add to Pantry',
                                Icons.add_circle_outline,
                                AppColors.primary,
                                () => context.push(Routes.pantryEdit, extra: null),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickActionCard(
                                context,
                                'New Recipe',
                                Icons.restaurant_outlined,
                                AppColors.secondary,
                                () => context.push(Routes.recipeAdd),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Feature Cards
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Explore',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureCard(
                          context,
                          'My Pantry',
                          'Manage your ingredients and track expiration dates',
                          Icons.kitchen_outlined,
                          AppColors.primary,
                          () => context.push(Routes.pantry),
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureCard(
                          context,
                          'Recipes',
                          'Discover and create delicious recipes',
                          Icons.restaurant_menu_outlined,
                          AppColors.secondary,
                          () => context.push(Routes.recipes),
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureCard(
                          context,
                          'Shopping Lists',
                          'Create shopping lists from your recipes',
                          Icons.shopping_cart_outlined,
                          AppColors.warning,
                          () => context.push(Routes.shoppingLists),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
              ],
            ),
          ),
          // Notification Overlay
          const NotificationOverlay(),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color,
                color.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.gray200,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gray200.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitial(String displayName, String email) {
    try {
      final safeDisplayName = displayName.trim();
      if (safeDisplayName.isNotEmpty) {
        return safeDisplayName[0].toUpperCase();
      }
      final safeEmail = email.trim();
      if (safeEmail.isNotEmpty) {
        return safeEmail[0].toUpperCase();
      }
    } catch (e) {
      // Fallback if any error occurs
    }
    return 'U';
  }

  Widget _buildDrawer(
      BuildContext context, WidgetRef ref, AsyncValue userAsync) {
    return Drawer(
      child: Column(
        children: [
          // User Profile Header
          userAsync.when(
            data: (user) {
              if (user == null) return const SizedBox.shrink();

              return UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: user.photoURL != null
                      ? ClipOval(
                          child: Image.network(
                            user.photoURL!,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Text(
                          _getInitial(
                            user.displayName ?? '', 
                            user.email ?? '',
                          ),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                ),
                accountName: Text(
                  (user.displayName.isNotEmpty 
                      ? user.displayName 
                      : (user.email.isNotEmpty ? user.email : 'User')),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                accountEmail: Text(user.email),
              );
            },
            loading: () => const DrawerHeader(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const DrawerHeader(
              child: Text('Error loading profile'),
            ),
          ),

          // Menu Items
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              context.push(Routes.profile);
            },
          ),
          ListTile(
            leading: const Icon(Icons.kitchen_outlined),
            title: const Text('Pantry'),
            onTap: () {
              Navigator.pop(context);
              context.push(Routes.pantry);
            },
          ),
          ListTile(
            leading: const Icon(Icons.restaurant_menu_outlined),
            title: const Text('Recipes'),
            onTap: () {
              Navigator.pop(context);
              context.push(Routes.recipes);
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart_outlined),
            title: const Text('Shopping Lists'),
            onTap: () {
              Navigator.pop(context);
              context.push(Routes.shoppingLists);
            },
          ),
          ListTile(
            leading: const Icon(Icons.feedback_rounded, color: AppColors.secondary),
            title: const Text('Support & Feedback'),
            onTap: () {
              Navigator.pop(context);
              context.push(Routes.feedback);
            },
          ),
          // Admin Section
          userAsync.when(
            data: (user) {
              if (user?.isAdmin == true) {
                return Column(
                  children: [
                    const Divider(),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      title: const Text(
                        'Admin Panel',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        context.push(Routes.adminDashboard);
                      },
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const Spacer(),

          // Logout Button
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: () async {
              Navigator.pop(context);
              await _handleLogout(context, ref);
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authControllerProvider.notifier).signOut();
      Logger.success('User logged out', 'HomeScreen');

      if (context.mounted) {
        context.go(Routes.login);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

