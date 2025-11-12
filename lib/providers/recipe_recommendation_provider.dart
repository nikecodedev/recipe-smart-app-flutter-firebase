import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/recipe_recommendation_service.dart';
import '../models/recipe_model.dart';
import '../models/pantry_item_model.dart';
import 'recipe_provider.dart';
import 'pantry_provider.dart';
import 'profile_provider.dart';
import '../services/firestore/firestore_service.dart';

/// Provider for recipe recommendations stream
/// Combines pantry items and recipes streams to provide real-time recommendations
final recipeRecommendationsStreamProvider =
    StreamProvider<List<RecipeRecommendation>>((ref) {
  final pantryItemsAsync = ref.watch(pantryItemsStreamProvider);
  final recipesAsync = ref.watch(allRecipesStreamProvider);

  // Wait for both streams to have data
  return pantryItemsAsync.when(
    data: (pantryItems) {
      return recipesAsync.when(
        data: (recipes) {
          return Stream.value(
            RecipeRecommendationService.getRecommendedRecipes(
              pantryItems: pantryItems,
              allRecipes: recipes,
              minCoverage: 0.0, // Show any recipe with at least one match
            ),
          );
        },
        loading: () => Stream.value(<RecipeRecommendation>[]),
        error: (error, stackTrace) => Stream.value(<RecipeRecommendation>[]),
      );
    },
    loading: () => Stream.value(<RecipeRecommendation>[]),
    error: (error, stackTrace) => Stream.value(<RecipeRecommendation>[]),
  );
});

/// Provider for recipe recommendations (non-stream, for one-time fetch)
final recipeRecommendationsProvider =
    FutureProvider<List<RecipeRecommendation>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return [];
  }

  final firestoreService = ref.watch(firestoreServiceProvider);

  try {
    // Fetch pantry items and recipes
    final pantryItems = await firestoreService.getPantryItems(userId);
    final recipes = await firestoreService.getAllRecipes();

    return RecipeRecommendationService.getRecommendedRecipes(
      pantryItems: pantryItems,
      allRecipes: recipes,
      minCoverage: 0.0, // Show any recipe with at least one match
    );
  } catch (e) {
    return [];
  }
});

