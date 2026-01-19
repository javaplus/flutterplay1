import 'package:drift/drift.dart';
import '../models/app_database.dart';
import '../../domain/entities/load_recipe.dart' as domain;

/// Local data source for LoadRecipe using Drift database
class LoadRecipeLocalDataSource {
  final AppDatabase database;

  LoadRecipeLocalDataSource(this.database);

  /// Get all load recipes
  Future<List<domain.LoadRecipe>> getAllLoadRecipes() async {
    final query = database.select(database.loadRecipes)
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);
    final results = await query.get();
    return results.map((data) => data.toEntity()).toList();
  }

  /// Get a load recipe by ID
  Future<domain.LoadRecipe?> getLoadRecipeById(String loadId) async {
    final query = database.select(database.loadRecipes)
      ..where((t) => t.loadId.equals(loadId));
    final result = await query.getSingleOrNull();
    return result?.toEntity();
  }

  /// Add a new load recipe
  Future<void> addLoadRecipe(domain.LoadRecipe loadRecipe) async {
    await database.into(database.loadRecipes).insert(loadRecipe.toCompanion());
  }

  /// Update an existing load recipe
  Future<void> updateLoadRecipe(domain.LoadRecipe loadRecipe) async {
    await (database.update(database.loadRecipes)
          ..where((t) => t.loadId.equals(loadRecipe.id)))
        .write(loadRecipe.toCompanion());
  }

  /// Delete a load recipe by ID
  Future<void> deleteLoadRecipe(String loadId) async {
    await (database.delete(
      database.loadRecipes,
    )..where((t) => t.loadId.equals(loadId))).go();
  }

  /// Search load recipes by cartridge, bullet type, powder type, etc.
  Future<List<domain.LoadRecipe>> searchLoadRecipes(String query) async {
    final lowerQuery = query.toLowerCase();

    final results = await database.select(database.loadRecipes).get();

    final filtered = results.where((data) {
      return data.cartridge.toLowerCase().contains(lowerQuery) ||
          data.bulletType.toLowerCase().contains(lowerQuery) ||
          data.powderType.toLowerCase().contains(lowerQuery) ||
          data.primerType.toLowerCase().contains(lowerQuery) ||
          data.brassType.toLowerCase().contains(lowerQuery);
    }).toList();

    return filtered.map((data) => data.toEntity()).toList();
  }
}
