import '../../domain/entities/load_recipe.dart';
import '../../domain/repositories/load_recipe_repository.dart';
import '../datasources/load_recipe_local_datasource.dart';

/// Implementation of LoadRecipeRepository using local data source
class LoadRecipeRepositoryImpl implements LoadRecipeRepository {
  final LoadRecipeLocalDataSource localDataSource;

  LoadRecipeRepositoryImpl(this.localDataSource);

  @override
  Future<List<LoadRecipe>> getAllLoadRecipes() async {
    return await localDataSource.getAllLoadRecipes();
  }

  @override
  Future<LoadRecipe?> getLoadRecipeById(String id) async {
    return await localDataSource.getLoadRecipeById(id);
  }

  @override
  Future<void> addLoadRecipe(LoadRecipe loadRecipe) async {
    await localDataSource.addLoadRecipe(loadRecipe);
  }

  @override
  Future<void> updateLoadRecipe(LoadRecipe loadRecipe) async {
    await localDataSource.updateLoadRecipe(loadRecipe);
  }

  @override
  Future<void> deleteLoadRecipe(String id) async {
    await localDataSource.deleteLoadRecipe(id);
  }

  @override
  Future<List<LoadRecipe>> searchLoadRecipes(String query) async {
    return await localDataSource.searchLoadRecipes(query);
  }
}
