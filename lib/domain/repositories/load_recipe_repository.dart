import '../entities/load_recipe.dart';

/// Repository interface for LoadRecipe operations
/// This defines the contract that the data layer must implement
abstract class LoadRecipeRepository {
  /// Get all load recipes
  Future<List<LoadRecipe>> getAllLoadRecipes();

  /// Get a load recipe by ID
  Future<LoadRecipe?> getLoadRecipeById(String id);

  /// Add a new load recipe
  Future<void> addLoadRecipe(LoadRecipe loadRecipe);

  /// Update an existing load recipe
  Future<void> updateLoadRecipe(LoadRecipe loadRecipe);

  /// Delete a load recipe by ID
  Future<void> deleteLoadRecipe(String id);

  /// Search load recipes by cartridge, bullet type, powder type, etc.
  Future<List<LoadRecipe>> searchLoadRecipes(String query);
}
