import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../services/firestore/firestore_service.dart';
import '../models/recipe_model.dart';
import '../core/utils/logger.dart';
import 'profile_provider.dart';
import 'auth_provider.dart';

/// Provider for all recipes stream
final allRecipesStreamProvider = StreamProvider<List<Recipe>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamAllRecipes();
});

/// Provider for user recipes stream
final userRecipesStreamProvider = StreamProvider<List<Recipe>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream.value([]);
  }

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamUserRecipes(userId);
});

/// Provider for recipe loading state
final recipeLoadingProvider = StateProvider<bool>((ref) => false);

/// Provider for recipe error message
final recipeErrorProvider = StateProvider<String?>((ref) => null);

/// Recipe controller for handling recipe operations
class RecipeController extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;
  final Ref _ref;

  RecipeController(this._firestoreService, this._ref)
      : super(const AsyncValue.data(null));

  /// Add a new recipe
  Future<String> addRecipe(Recipe recipe, {File? imageFile}) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      throw Exception('No user logged in');
    }

    state = const AsyncValue.loading();
    _ref.read(recipeErrorProvider.notifier).state = null;

    try {
      // First add the recipe to get the ID
      final recipeId = await _firestoreService.addRecipe(recipe);

      // If there's an image, upload it and update the recipe
      if (imageFile != null) {
        final imageUrl = await _firestoreService.uploadRecipeImage(recipeId, imageFile);
        // Update recipe with image URL
        final updatedRecipe = recipe.copyWith(id: recipeId, imageUrl: imageUrl);
        await _firestoreService.updateRecipe(updatedRecipe);
      }

      state = const AsyncValue.data(null);
      return recipeId;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      _ref.read(recipeErrorProvider.notifier).state = e.toString();
      rethrow;
    }
  }

  /// Delete a recipe
  Future<void> deleteRecipe(String recipeId, {String? imageUrl}) async {
    state = const AsyncValue.loading();
    _ref.read(recipeErrorProvider.notifier).state = null;

    try {
      // Delete image if exists
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          await _firestoreService.deleteRecipeImage(imageUrl);
        } catch (e) {
          // Log but don't fail if image deletion fails
          Logger.error('Failed to delete recipe image', e, null, 'RecipeController');
        }
      }

      // Delete recipe
      await _firestoreService.deleteRecipe(recipeId);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      _ref.read(recipeErrorProvider.notifier).state = e.toString();
      rethrow;
    }
  }
}

/// Provider for RecipeController
final recipeControllerProvider =
    StateNotifierProvider<RecipeController, AsyncValue<void>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return RecipeController(firestoreService, ref);
});

