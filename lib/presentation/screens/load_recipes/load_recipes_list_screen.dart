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
  Set<String> _selectedBulletTypes = {};
  Set<String> _selectedPowderTypes = {};
  Set<String> _selectedPrimerTypes = {};
  Set<String> _selectedBrassTypes = {};

  int get _totalActiveFilters =>
      _selectedCartridges.length +
      _selectedBulletTypes.length +
      _selectedPowderTypes.length +
      _selectedPrimerTypes.length +
      _selectedBrassTypes.length;

  bool get _hasActiveFilters => _totalActiveFilters > 0;

  void _clearAllFilters() {
    setState(() {
      _selectedCartridges.clear();
      _selectedBulletTypes.clear();
      _selectedPowderTypes.clear();
      _selectedPrimerTypes.clear();
      _selectedBrassTypes.clear();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allRecipesAsync = ref.watch(loadRecipesListProvider);
    final loadRecipesAsync = _searchQuery.isEmpty
        ? allRecipesAsync
        : ref.watch(loadRecipeSearchProvider(_searchQuery));
    final fieldValues = ref.watch(distinctRecipeFieldValuesProvider);

    final hasAnyFilterOptions =
        fieldValues.values.any((list) => list.isNotEmpty);

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
            isLabelVisible: _hasActiveFilters,
            label: Text('$_totalActiveFilters'),
            child: IconButton(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filter recipes',
              onPressed: hasAnyFilterOptions
                  ? () => _showFilterSheet(fieldValues)
                  : null,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Active filter chip row
          if (_hasActiveFilters)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  ..._buildActiveFilterChips(),
                  TextButton(
                    onPressed: _clearAllFilters,
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
                  final filtered = _applyFilters(loadRecipes);

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
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
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

  List<Widget> _buildActiveFilterChips() {
    final chips = <Widget>[];

    void addChips(Set<String> selection, void Function(String) onRemove) {
      for (final value in selection) {
        chips.add(
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(value),
              selected: true,
              onSelected: (_) => onRemove(value),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => onRemove(value),
            ),
          ),
        );
      }
    }

    addChips(
      _selectedCartridges,
      (v) => setState(() => _selectedCartridges.remove(v)),
    );
    addChips(
      _selectedBulletTypes,
      (v) => setState(() => _selectedBulletTypes.remove(v)),
    );
    addChips(
      _selectedPowderTypes,
      (v) => setState(() => _selectedPowderTypes.remove(v)),
    );
    addChips(
      _selectedPrimerTypes,
      (v) => setState(() => _selectedPrimerTypes.remove(v)),
    );
    addChips(
      _selectedBrassTypes,
      (v) => setState(() => _selectedBrassTypes.remove(v)),
    );

    return chips;
  }

  List _applyFilters(List loadRecipes) {
    if (!_hasActiveFilters) return loadRecipes;
    return loadRecipes.where((r) {
      if (_selectedCartridges.isNotEmpty &&
          !_selectedCartridges.contains(r.cartridge)) {
        return false;
      }
      if (_selectedBulletTypes.isNotEmpty &&
          !_selectedBulletTypes.contains(r.bulletType)) {
        return false;
      }
      if (_selectedPowderTypes.isNotEmpty &&
          !(r.powderType != null &&
              _selectedPowderTypes.contains(r.powderType))) {
        return false;
      }
      if (_selectedPrimerTypes.isNotEmpty &&
          !(r.primerType != null &&
              _selectedPrimerTypes.contains(r.primerType))) {
        return false;
      }
      if (_selectedBrassTypes.isNotEmpty &&
          !(r.brassType != null &&
              _selectedBrassTypes.contains(r.brassType))) {
        return false;
      }
      return true;
    }).toList();
  }

  Widget _buildEmptyState() {
    final String title;
    final String subtitle;
    if (_hasActiveFilters) {
      title = 'No recipes match the active filters';
      subtitle = 'Try adjusting or clearing the filters';
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
          if (_hasActiveFilters) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _clearAllFilters,
              icon: const Icon(Icons.filter_list_off),
              label: const Text('Clear Filters'),
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

  void _showFilterSheet(Map<String, List<String>> fieldValues) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => _RecipeFilterSheet(
        allCartridges: fieldValues['cartridge'] ?? [],
        allBulletTypes: fieldValues['bulletType'] ?? [],
        allPowderTypes: fieldValues['powderType'] ?? [],
        allPrimerTypes: fieldValues['primerType'] ?? [],
        allBrassTypes: fieldValues['brassType'] ?? [],
        selectedCartridges: Set.from(_selectedCartridges),
        selectedBulletTypes: Set.from(_selectedBulletTypes),
        selectedPowderTypes: Set.from(_selectedPowderTypes),
        selectedPrimerTypes: Set.from(_selectedPrimerTypes),
        selectedBrassTypes: Set.from(_selectedBrassTypes),
        onApply: ({
          required Set<String> cartridges,
          required Set<String> bulletTypes,
          required Set<String> powderTypes,
          required Set<String> primerTypes,
          required Set<String> brassTypes,
        }) {
          setState(() {
            _selectedCartridges = cartridges;
            _selectedBulletTypes = bulletTypes;
            _selectedPowderTypes = powderTypes;
            _selectedPrimerTypes = primerTypes;
            _selectedBrassTypes = brassTypes;
          });
        },
      ),
    );
  }
}

/// Unified bottom sheet for filtering recipes across all component fields.
class _RecipeFilterSheet extends StatefulWidget {
  final List<String> allCartridges;
  final List<String> allBulletTypes;
  final List<String> allPowderTypes;
  final List<String> allPrimerTypes;
  final List<String> allBrassTypes;
  final Set<String> selectedCartridges;
  final Set<String> selectedBulletTypes;
  final Set<String> selectedPowderTypes;
  final Set<String> selectedPrimerTypes;
  final Set<String> selectedBrassTypes;
  final void Function({
    required Set<String> cartridges,
    required Set<String> bulletTypes,
    required Set<String> powderTypes,
    required Set<String> primerTypes,
    required Set<String> brassTypes,
  })
  onApply;

  const _RecipeFilterSheet({
    required this.allCartridges,
    required this.allBulletTypes,
    required this.allPowderTypes,
    required this.allPrimerTypes,
    required this.allBrassTypes,
    required this.selectedCartridges,
    required this.selectedBulletTypes,
    required this.selectedPowderTypes,
    required this.selectedPrimerTypes,
    required this.selectedBrassTypes,
    required this.onApply,
  });

  @override
  State<_RecipeFilterSheet> createState() => _RecipeFilterSheetState();
}

class _RecipeFilterSheetState extends State<_RecipeFilterSheet> {
  late Set<String> _cartridges;
  late Set<String> _bulletTypes;
  late Set<String> _powderTypes;
  late Set<String> _primerTypes;
  late Set<String> _brassTypes;

  @override
  void initState() {
    super.initState();
    _cartridges = Set.from(widget.selectedCartridges);
    _bulletTypes = Set.from(widget.selectedBulletTypes);
    _powderTypes = Set.from(widget.selectedPowderTypes);
    _primerTypes = Set.from(widget.selectedPrimerTypes);
    _brassTypes = Set.from(widget.selectedBrassTypes);
  }

  int get _totalSelected =>
      _cartridges.length +
      _bulletTypes.length +
      _powderTypes.length +
      _primerTypes.length +
      _brassTypes.length;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.filter_list, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Filter Recipes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_totalSelected > 0)
                  TextButton(
                    onPressed: () => setState(() {
                      _cartridges.clear();
                      _bulletTypes.clear();
                      _powderTypes.clear();
                      _primerTypes.clear();
                      _brassTypes.clear();
                    }),
                    child: const Text('Clear all'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Scrollable filter sections
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              children: [
                if (widget.allCartridges.isNotEmpty) ...[
                  _buildSection('Caliber', widget.allCartridges, _cartridges),
                  const SizedBox(height: 20),
                ],
                if (widget.allBulletTypes.isNotEmpty) ...[
                  _buildSection(
                    'Bullet Type',
                    widget.allBulletTypes,
                    _bulletTypes,
                  ),
                  const SizedBox(height: 20),
                ],
                if (widget.allPowderTypes.isNotEmpty) ...[
                  _buildSection('Powder', widget.allPowderTypes, _powderTypes),
                  const SizedBox(height: 20),
                ],
                if (widget.allPrimerTypes.isNotEmpty) ...[
                  _buildSection('Primer', widget.allPrimerTypes, _primerTypes),
                  const SizedBox(height: 20),
                ],
                if (widget.allBrassTypes.isNotEmpty) ...[
                  _buildSection('Brass', widget.allBrassTypes, _brassTypes),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
          // Action buttons
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              12,
              24,
              MediaQuery.of(context).padding.bottom + 12,
            ),
            child: Row(
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
                      widget.onApply(
                        cartridges: _cartridges,
                        bulletTypes: _bulletTypes,
                        powderTypes: _powderTypes,
                        primerTypes: _primerTypes,
                        brassTypes: _brassTypes,
                      );
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      _totalSelected > 0
                          ? 'Apply ($_totalSelected)'
                          : 'Apply',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String label,
    List<String> options,
    Set<String> selection,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: options.map((option) {
            final selected = selection.contains(option);
            return FilterChip(
              label: Text(option),
              selected: selected,
              onSelected: (checked) {
                setState(() {
                  if (checked) {
                    selection.add(option);
                  } else {
                    selection.remove(option);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
