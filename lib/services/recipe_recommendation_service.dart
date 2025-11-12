import '../models/recipe_model.dart';
import '../models/pantry_item_model.dart';
import '../core/utils/logger.dart';

/// Model for recipe recommendation with coverage info
class RecipeRecommendation {
  final Recipe recipe;
  final double coveragePercentage; // 0.0 to 1.0
  final List<RecipeIngredient> availableIngredients;
  final List<RecipeIngredient> missingIngredients;

  RecipeRecommendation({
    required this.recipe,
    required this.coveragePercentage,
    required this.availableIngredients,
    required this.missingIngredients,
  });

  /// Get coverage percentage as integer (0-100)
  int get coveragePercent => (coveragePercentage * 100).round();
}

/// Service for recommending recipes based on pantry items
class RecipeRecommendationService {
  /// Normalize ingredient name for comparison
  /// Removes extra spaces, converts to lowercase, handles common variations
  static String _normalizeIngredientName(String name) {
    return name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ') // Multiple spaces to single space
        .replaceAll(RegExp(r'[^\w\s]'), ''); // Remove special characters
  }

  /// Check if two ingredient names match (fuzzy matching)
  static bool _ingredientNamesMatch(String name1, String name2) {
    final normalized1 = _normalizeIngredientName(name1);
    final normalized2 = _normalizeIngredientName(name2);

    // Exact match
    if (normalized1 == normalized2) return true;

    // Check if one contains the other (for cases like "tomato" vs "tomatoes")
    if (normalized1.contains(normalized2) || normalized2.contains(normalized1)) {
      // Additional check to avoid false positives
      final shorter = normalized1.length < normalized2.length ? normalized1 : normalized2;
      final longer = normalized1.length >= normalized2.length ? normalized1 : normalized2;
      
      // If shorter is at least 70% of longer, consider it a match
      if (shorter.length >= (longer.length * 0.7)) {
        return true;
      }
    }

    // Handle plural/singular variations
    final singular1 = normalized1.replaceAll(RegExp(r's$'), '');
    final singular2 = normalized2.replaceAll(RegExp(r's$'), '');
    if (singular1 == singular2 && singular1.length > 2) return true;

    return false;
  }

  /// Get recommended recipes based on pantry items
  /// Returns recipes that have at least one matching ingredient
  /// Calculates match probability based on type and number of matching elements
  static List<RecipeRecommendation> getRecommendedRecipes({
    required List<PantryItem> pantryItems,
    required List<Recipe> allRecipes,
    double minCoverage = 0.0, // Show any recipe with at least one match
  }) {
    try {
      if (pantryItems.isEmpty) {
        Logger.info('No pantry items available for recommendations', 'RecipeRecommendationService');
        return [];
      }

      if (allRecipes.isEmpty) {
        Logger.info('No recipes available for recommendations', 'RecipeRecommendationService');
        return [];
      }

      // Create a map of pantry items by normalized name for quick lookup
      final pantryMap = <String, PantryItem>{};
      for (final item in pantryItems) {
        final normalizedName = _normalizeIngredientName(item.name);
        // Store the first occurrence (or could use quantity-based logic)
        if (!pantryMap.containsKey(normalizedName)) {
          pantryMap[normalizedName] = item;
        }
      }

      final recommendations = <RecipeRecommendation>[];

      for (final recipe in allRecipes) {
        if (recipe.ingredients.isEmpty) continue;

        final availableIngredients = <RecipeIngredient>[];
        final missingIngredients = <RecipeIngredient>[];

        // Check each recipe ingredient against pantry items
        for (final recipeIngredient in recipe.ingredients) {
          bool found = false;

          // Try to find matching pantry item
          for (final pantryItem in pantryItems) {
            if (_ingredientNamesMatch(recipeIngredient.name, pantryItem.name)) {
              availableIngredients.add(recipeIngredient);
              found = true;
              break;
            }
          }

          if (!found) {
            missingIngredients.add(recipeIngredient);
          }
        }

        // Only include recipes that have at least one matching ingredient
        if (availableIngredients.isEmpty) continue;

        // Calculate match probability based on:
        // 1. Number of matching ingredients (weight: 70%)
        // 2. Ratio of matched to total ingredients (weight: 30%)
        final totalIngredients = recipe.ingredients.length;
        final matchedCount = availableIngredients.length;
        final matchRatio = matchedCount / totalIngredients;

        // Weighted probability calculation
        // Higher weight for having more matches, plus bonus for higher ratio
        final matchScore = (matchedCount / totalIngredients) * 0.7 + matchRatio * 0.3;
        
        // Normalize to 0-1 range (ensuring it reflects actual coverage)
        final coverage = matchRatio.clamp(0.0, 1.0);

        // Only include recipes that meet minimum coverage threshold
        if (coverage >= minCoverage) {
          recommendations.add(RecipeRecommendation(
            recipe: recipe,
            coveragePercentage: coverage,
            availableIngredients: availableIngredients,
            missingIngredients: missingIngredients,
          ));
        }
      }

      // Sort by match probability (coverage percentage) - highest first, then by number of matches
      recommendations.sort((a, b) {
        // Primary sort: coverage percentage (match probability)
        final coverageCompare = b.coveragePercentage.compareTo(a.coveragePercentage);
        if (coverageCompare != 0) return coverageCompare;
        
        // Secondary sort: number of matched ingredients
        final matchCountCompare = b.availableIngredients.length.compareTo(a.availableIngredients.length);
        if (matchCountCompare != 0) return matchCountCompare;
        
        // Tertiary sort: recipe title
        return a.recipe.title.compareTo(b.recipe.title);
      });

      Logger.success(
        'Found ${recommendations.length} recommended recipes with matching ingredients',
        'RecipeRecommendationService',
      );

      return recommendations;
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to get recommended recipes',
        e,
        stackTrace,
        'RecipeRecommendationService',
      );
      return [];
    }
  }

}

