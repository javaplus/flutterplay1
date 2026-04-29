import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/load_recipe_local_datasource.dart';
import '../../data/repositories/load_recipe_repository_impl.dart';
import '../../domain/repositories/load_recipe_repository.dart';
import '../../domain/entities/load_recipe.dart';
import 'firearm_provider.dart'; // For databaseProvider

/// Provider for LoadRecipe local data source
final loadRecipeLocalDataSourceProvider = Provider<LoadRecipeLocalDataSource>((
  ref,
) {
  final database = ref.watch(databaseProvider);
  return LoadRecipeLocalDataSource(database);
});

/// Provider for LoadRecipe repository
final loadRecipeRepositoryProvider = Provider<LoadRecipeRepository>((ref) {
  final localDataSource = ref.watch(loadRecipeLocalDataSourceProvider);
  return LoadRecipeRepositoryImpl(localDataSource);
});

/// Provider for the list of all load recipes
final loadRecipesListProvider = FutureProvider<List<LoadRecipe>>((ref) async {
  final repository = ref.watch(loadRecipeRepositoryProvider);
  return await repository.getAllLoadRecipes();
});

/// Provider for a single load recipe by ID
final loadRecipeByIdProvider = FutureProvider.family<LoadRecipe?, String>((
  ref,
  id,
) async {
  final repository = ref.watch(loadRecipeRepositoryProvider);
  return await repository.getLoadRecipeById(id);
});

/// Provider for search results
final loadRecipeSearchProvider =
    FutureProvider.family<List<LoadRecipe>, String>((ref, query) async {
      final repository = ref.watch(loadRecipeRepositoryProvider);
      if (query.isEmpty) {
        return await repository.getAllLoadRecipes();
      }
      return await repository.searchLoadRecipes(query);
    });

/// Notifier for managing load recipe CRUD operations
class LoadRecipeNotifier extends StateNotifier<AsyncValue<void>> {
  final LoadRecipeRepository repository;

  LoadRecipeNotifier(this.repository) : super(const AsyncValue.data(null));

  /// Add a new load recipe
  Future<void> addLoadRecipe(LoadRecipe loadRecipe) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.addLoadRecipe(loadRecipe);
    });
  }

  /// Update an existing load recipe
  Future<void> updateLoadRecipe(LoadRecipe loadRecipe) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.updateLoadRecipe(loadRecipe);
    });
  }

  /// Delete a load recipe
  Future<void> deleteLoadRecipe(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.deleteLoadRecipe(id);
    });
  }
}

/// Provider for load recipe notifier
final loadRecipeNotifierProvider =
    StateNotifierProvider<LoadRecipeNotifier, AsyncValue<void>>((ref) {
      final repository = ref.watch(loadRecipeRepositoryProvider);
      return LoadRecipeNotifier(repository);
    });

/// Provider for distinct field values across all recipes.
/// Used for autocomplete suggestions in the wizard and filter chips in the list.
final distinctRecipeFieldValuesProvider = Provider<Map<String, List<String>>>((
  ref,
) {
  final recipesAsync = ref.watch(loadRecipesListProvider);
  return recipesAsync.maybeWhen(
    data: (recipes) {
      final cartridges = <String>{};
      final bulletTypes = <String>{};
      final powderTypes = <String>{};
      final primerTypes = <String>{};
      final brassTypes = <String>{};
      for (final recipe in recipes) {
        cartridges.add(recipe.cartridge);
        if (recipe.bulletType.isNotEmpty) bulletTypes.add(recipe.bulletType);
        if (recipe.powderType?.isNotEmpty == true) {
          powderTypes.add(recipe.powderType!);
        }
        if (recipe.primerType?.isNotEmpty == true) {
          primerTypes.add(recipe.primerType!);
        }
        if (recipe.brassType?.isNotEmpty == true) {
          brassTypes.add(recipe.brassType!);
        }
      }
      return {
        'cartridge': (cartridges.toList()..sort()),
        'bulletType': (bulletTypes.toList()..sort()),
        'powderType': (powderTypes.toList()..sort()),
        'primerType': (primerTypes.toList()..sort()),
        'brassType': (brassTypes.toList()..sort()),
      };
    },
    orElse: () => {
      'cartridge': <String>[],
      'bulletType': <String>[],
      'powderType': <String>[],
      'primerType': <String>[],
      'brassType': <String>[],
    },
  );
});
