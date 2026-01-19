import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/load_recipe_provider.dart';
import '../../widgets/load_recipe_card.dart';
import 'load_recipe_detail_screen.dart';
import 'add_edit_load_recipe_wizard.dart';

/// Main screen displaying the list of load recipes
class LoadRecipesListScreen extends ConsumerStatefulWidget {
  const LoadRecipesListScreen({super.key});

  @override
  ConsumerState<LoadRecipesListScreen> createState() =>
      _LoadRecipesListScreenState();
}

class _LoadRecipesListScreenState extends ConsumerState<LoadRecipesListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loadRecipesAsync = _searchQuery.isEmpty
        ? ref.watch(loadRecipesListProvider)
        : ref.watch(loadRecipeSearchProvider(_searchQuery));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Load Recipes'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(loadRecipesListProvider);
        },
        child: loadRecipesAsync.when(
          data: (loadRecipes) {
            if (loadRecipes.isEmpty) {
              return _buildEmptyState();
            }
            return ListView.builder(
              itemCount: loadRecipes.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final loadRecipe = loadRecipes[index];
                return LoadRecipeCard(
                  loadRecipe: loadRecipe,
                  onTap: () => _navigateToDetail(loadRecipe.id),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading load recipes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(loadRecipesListProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddLoadRecipe,
        icon: const Icon(Icons.add),
        label: const Text('Add Load Recipe'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.science_outlined, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isEmpty ? 'No load recipes yet' : 'No recipes found',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Add your first load recipe to get started'
                : 'Try a different search term',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToAddLoadRecipe,
              icon: const Icon(Icons.add),
              label: const Text('Add Load Recipe'),
            ),
          ],
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Load Recipes'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Enter cartridge, bullet, or powder type',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
          onSubmitted: (value) {
            setState(() {
              _searchQuery = value;
            });
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = _searchController.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(String loadRecipeId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            LoadRecipeDetailScreen(loadRecipeId: loadRecipeId),
      ),
    );
  }

  void _navigateToAddLoadRecipe() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddEditLoadRecipeWizard()),
    );
  }
}
