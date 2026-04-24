import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/load_recipe_provider.dart';
import '../../widgets/load_recipe_card.dart';
import 'load_recipe_detail_screen.dart';
import 'add_edit_load_recipe_wizard.dart';
import '../range_sessions/add_range_session_wizard.dart';
import '../range_sessions/range_sessions_list_screen.dart';

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
  Set<String> _selectedCartridges = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Always watch the full list to derive available cartridges
    final allRecipesAsync = ref.watch(loadRecipesListProvider);
    final loadRecipesAsync = _searchQuery.isEmpty
        ? allRecipesAsync
        : ref.watch(loadRecipeSearchProvider(_searchQuery));

    // Derive sorted distinct cartridges from all recipes
    final allCartridges = allRecipesAsync.maybeWhen(
      data: (list) => (list.map((r) => r.cartridge).toSet().toList()..sort()),
      orElse: () => <String>[],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Load Recipes'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          Badge(
            isLabelVisible: _selectedCartridges.isNotEmpty,
            label: Text('${_selectedCartridges.length}'),
            child: IconButton(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filter by cartridge',
              onPressed: allCartridges.isEmpty
                  ? null
                  : () => _showCartridgeFilter(allCartridges),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Active filter chip row
          if (_selectedCartridges.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  ..._selectedCartridges.map(
                    (cartridge) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cartridge),
                        selected: true,
                        onSelected: (_) => setState(
                          () => _selectedCartridges.remove(cartridge),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => setState(
                          () => _selectedCartridges.remove(cartridge),
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => _selectedCartridges.clear()),
                    child: const Text('Clear all'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(loadRecipesListProvider);
              },
              child: loadRecipesAsync.when(
                data: (loadRecipes) {
                  // Apply cartridge filter client-side
                  final filtered = _selectedCartridges.isEmpty
                      ? loadRecipes
                      : loadRecipes
                            .where(
                              (r) => _selectedCartridges.contains(r.cartridge),
                            )
                            .toList();

                  if (filtered.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.builder(
                    itemCount: filtered.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final loadRecipe = filtered[index];
                      return LoadRecipeCard(
                        loadRecipe: loadRecipe,
                        onTap: () => _navigateToDetail(loadRecipe.id),
                        onStartRangeSession: () =>
                            _navigateToRangeSession(loadRecipe.id),
                        onViewSessions: () =>
                            _navigateToRangeSessions(loadRecipe.id),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.red[300],
                      ),
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
                        onPressed: () =>
                            ref.invalidate(loadRecipesListProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddLoadRecipe,
        icon: const Icon(Icons.add),
        label: const Text('Add Load Recipe'),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isFiltered = _selectedCartridges.isNotEmpty;
    final String title;
    final String subtitle;
    if (isFiltered) {
      title = 'No recipes match the selected cartridge(s)';
      subtitle = 'Try adjusting or clearing the cartridge filter';
    } else if (_searchQuery.isNotEmpty) {
      title = 'No recipes found';
      subtitle = 'Try a different search term';
    } else {
      title = 'No load recipes yet';
      subtitle = 'Add your first load recipe to get started';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.science_outlined, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          if (isFiltered) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => setState(() => _selectedCartridges.clear()),
              icon: const Icon(Icons.filter_list_off),
              label: const Text('Clear Filter'),
            ),
          ] else if (_searchQuery.isEmpty) ...[
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

  void _navigateToRangeSession(String loadRecipeId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            AddRangeSessionWizard(initialLoadRecipeId: loadRecipeId),
      ),
    );
  }

  void _navigateToRangeSessions(String loadRecipeId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            RangeSessionsListScreen(initialLoadRecipeId: loadRecipeId),
      ),
    );
  }

  void _navigateToAddLoadRecipe() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddEditLoadRecipeWizard()),
    );
  }

  void _showCartridgeFilter(List<String> allCartridges) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => _CartridgeFilterSheet(
        allCartridges: allCartridges,
        initialSelection: Set.from(_selectedCartridges),
        onApply: (selected) => setState(() => _selectedCartridges = selected),
      ),
    );
  }
}

/// Bottom sheet for selecting cartridge filters
class _CartridgeFilterSheet extends StatefulWidget {
  final List<String> allCartridges;
  final Set<String> initialSelection;
  final void Function(Set<String>) onApply;

  const _CartridgeFilterSheet({
    required this.allCartridges,
    required this.initialSelection,
    required this.onApply,
  });

  @override
  State<_CartridgeFilterSheet> createState() => _CartridgeFilterSheetState();
}

class _CartridgeFilterSheetState extends State<_CartridgeFilterSheet> {
  late Set<String> _selection;

  @override
  void initState() {
    super.initState();
    _selection = Set.from(widget.initialSelection);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              const Icon(Icons.filter_list, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Filter by Cartridge',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (_selection.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _selection.clear()),
                  child: const Text('Clear all'),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Cartridge checkboxes
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: ListView(
              shrinkWrap: true,
              children: widget.allCartridges.map((cartridge) {
                return CheckboxListTile(
                  title: Text(cartridge),
                  value: _selection.contains(cartridge),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selection.add(cartridge);
                      } else {
                        _selection.remove(cartridge);
                      }
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    widget.onApply(_selection);
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
