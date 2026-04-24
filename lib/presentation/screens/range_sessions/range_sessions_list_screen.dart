import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/firearm.dart';
import '../../../domain/entities/load_recipe.dart';
import '../../providers/range_session_provider.dart';
import '../../providers/firearm_provider.dart';
import '../../providers/load_recipe_provider.dart';
import '../../widgets/range_session_card.dart';
import 'range_session_detail_screen.dart';
import 'add_range_session_wizard.dart';

/// Main screen displaying the list of range sessions
class RangeSessionsListScreen extends ConsumerStatefulWidget {
  final String? initialLoadRecipeId;

  const RangeSessionsListScreen({super.key, this.initialLoadRecipeId});

  @override
  ConsumerState<RangeSessionsListScreen> createState() =>
      _RangeSessionsListScreenState();
}

class _RangeSessionsListScreenState
    extends ConsumerState<RangeSessionsListScreen> {
  String? _selectedCaliberValue;
  String? _selectedFirearmId;
  String? _selectedLoadRecipeId;

  @override
  void initState() {
    super.initState();
    _selectedLoadRecipeId = widget.initialLoadRecipeId;
  }

  int get _activeFilterCount => [
    _selectedCaliberValue,
    _selectedFirearmId,
    _selectedLoadRecipeId,
  ].where((v) => v != null).length;

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(rangeSessionsListProvider);
    final firearmsAsync = ref.watch(firearmsListProvider);
    final loadRecipesAsync = ref.watch(loadRecipesListProvider);

    final firearmMap = firearmsAsync.maybeWhen(
      data: (list) => {for (final f in list) f.id: f},
      orElse: () => <String, Firearm>{},
    );
    final recipeMap = loadRecipesAsync.maybeWhen(
      data: (list) => {for (final r in list) r.id: r},
      orElse: () => <String, LoadRecipe>{},
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Range Sessions'),
        elevation: 2,
        actions: [
          Badge(
            isLabelVisible: _activeFilterCount > 0,
            label: Text('$_activeFilterCount'),
            child: IconButton(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filter sessions',
              onPressed: sessionsAsync.hasValue
                  ? () => _showFilterSheet(
                      context,
                      firearmMap,
                      recipeMap,
                      sessionsAsync.value!,
                    )
                  : null,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Active filter chip row
          if (_activeFilterCount > 0)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  if (_selectedCaliberValue != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_selectedCaliberValue!),
                        selected: true,
                        avatar: const Icon(Icons.straighten, size: 16),
                        onSelected: (_) =>
                            setState(() => _selectedCaliberValue = null),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () =>
                            setState(() => _selectedCaliberValue = null),
                      ),
                    ),
                  if (_selectedFirearmId != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          firearmMap[_selectedFirearmId]?.name ??
                              _selectedFirearmId!,
                        ),
                        selected: true,
                        avatar: const Icon(Icons.gps_fixed, size: 16),
                        onSelected: (_) =>
                            setState(() => _selectedFirearmId = null),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () =>
                            setState(() => _selectedFirearmId = null),
                      ),
                    ),
                  if (_selectedLoadRecipeId != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          recipeMap[_selectedLoadRecipeId] != null
                              ? '${recipeMap[_selectedLoadRecipeId]!.nickname} (${recipeMap[_selectedLoadRecipeId]!.cartridge})'
                              : _selectedLoadRecipeId!,
                        ),
                        selected: true,
                        avatar: const Icon(Icons.science, size: 16),
                        onSelected: (_) =>
                            setState(() => _selectedLoadRecipeId = null),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () =>
                            setState(() => _selectedLoadRecipeId = null),
                      ),
                    ),
                  TextButton(
                    onPressed: () => setState(() {
                      _selectedCaliberValue = null;
                      _selectedFirearmId = null;
                      _selectedLoadRecipeId = null;
                    }),
                    child: const Text('Clear all'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(rangeSessionsListProvider);
              },
              child: sessionsAsync.when(
                data: (sessions) {
                  // Apply filters with AND logic
                  final filtered = sessions.where((session) {
                    if (_selectedFirearmId != null &&
                        session.firearmId != _selectedFirearmId) {
                      return false;
                    }
                    if (_selectedLoadRecipeId != null &&
                        session.loadRecipeId != _selectedLoadRecipeId) {
                      return false;
                    }
                    if (_selectedCaliberValue != null) {
                      final caliber = firearmMap[session.firearmId]?.caliber;
                      if (caliber != _selectedCaliberValue) return false;
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final session = filtered[index];

                      final firearmAsync = ref.watch(
                        firearmByIdProvider(session.firearmId),
                      );
                      final loadRecipeAsync = ref.watch(
                        loadRecipeByIdProvider(session.loadRecipeId),
                      );
                      final targetsAsync = ref.watch(
                        targetsByRangeSessionIdProvider(session.id),
                      );

                      return firearmAsync.when(
                        data: (firearm) => loadRecipeAsync.when(
                          data: (loadRecipe) => targetsAsync.when(
                            data: (targets) => RangeSessionCard(
                              session: session,
                              firearm: firearm,
                              loadRecipe: loadRecipe,
                              targets: targets,
                              onTap: () => _navigateToDetail(session.id),
                            ),
                            loading: () => RangeSessionCard(
                              session: session,
                              firearm: firearm,
                              loadRecipe: loadRecipe,
                              onTap: () => _navigateToDetail(session.id),
                            ),
                            error: (_, __) => RangeSessionCard(
                              session: session,
                              firearm: firearm,
                              loadRecipe: loadRecipe,
                              onTap: () => _navigateToDetail(session.id),
                            ),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
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
                        'Error loading range sessions',
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
                            ref.invalidate(rangeSessionsListProvider),
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
        onPressed: _navigateToAddSession,
        icon: const Icon(Icons.add),
        label: const Text('Add Session'),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasFilters = _activeFilterCount > 0;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.my_location, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            hasFilters
                ? 'No sessions match the active filters'
                : 'No range sessions yet',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'Try adjusting or clearing the filters'
                : 'Add your first range session to get started',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (hasFilters)
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _selectedCaliberValue = null;
                _selectedFirearmId = null;
                _selectedLoadRecipeId = null;
              }),
              icon: const Icon(Icons.filter_list_off),
              label: const Text('Clear Filters'),
            )
          else
            ElevatedButton.icon(
              onPressed: _navigateToAddSession,
              icon: const Icon(Icons.add),
              label: const Text('Add Session'),
            ),
        ],
      ),
    );
  }

  void _showFilterSheet(
    BuildContext context,
    Map<String, Firearm> firearmMap,
    Map<String, LoadRecipe> recipeMap,
    List sessions,
  ) {
    // Derive available options from sessions that actually exist
    final caliberSet = <String>{};
    final firearmIdSet = <String>{};
    final recipeIdSet = <String>{};
    for (final session in sessions) {
      final caliber = firearmMap[session.firearmId]?.caliber;
      if (caliber != null) caliberSet.add(caliber);
      firearmIdSet.add(session.firearmId);
      recipeIdSet.add(session.loadRecipeId);
    }

    final availableCalibers = caliberSet.toList()..sort();
    final availableFirearms =
        firearmIdSet
            .where((id) => firearmMap.containsKey(id))
            .map((id) => firearmMap[id]!)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    final availableRecipes =
        recipeIdSet
            .where((id) => recipeMap.containsKey(id))
            .map((id) => recipeMap[id]!)
            .toList()
          ..sort((a, b) => a.nickname.compareTo(b.nickname));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => _RangeSessionFilterSheet(
        availableCalibers: availableCalibers,
        availableFirearms: availableFirearms,
        availableRecipes: availableRecipes,
        selectedCaliberValue: _selectedCaliberValue,
        selectedFirearmId: _selectedFirearmId,
        selectedLoadRecipeId: _selectedLoadRecipeId,
        onApply: (caliber, firearmId, recipeId) => setState(() {
          _selectedCaliberValue = caliber;
          _selectedFirearmId = firearmId;
          _selectedLoadRecipeId = recipeId;
        }),
      ),
    );
  }

  void _navigateToDetail(String sessionId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RangeSessionDetailScreen(sessionId: sessionId),
      ),
    );
  }

  void _navigateToAddSession() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddRangeSessionWizard()),
    );
  }
}

class _RangeSessionFilterSheet extends StatefulWidget {
  final List<String> availableCalibers;
  final List<Firearm> availableFirearms;
  final List<LoadRecipe> availableRecipes;
  final String? selectedCaliberValue;
  final String? selectedFirearmId;
  final String? selectedLoadRecipeId;
  final void Function(String? caliber, String? firearmId, String? recipeId)
  onApply;

  const _RangeSessionFilterSheet({
    required this.availableCalibers,
    required this.availableFirearms,
    required this.availableRecipes,
    required this.selectedCaliberValue,
    required this.selectedFirearmId,
    required this.selectedLoadRecipeId,
    required this.onApply,
  });

  @override
  State<_RangeSessionFilterSheet> createState() =>
      _RangeSessionFilterSheetState();
}

class _RangeSessionFilterSheetState extends State<_RangeSessionFilterSheet> {
  String? _caliberValue;
  String? _firearmId;
  String? _recipeId;

  @override
  void initState() {
    super.initState();
    _caliberValue = widget.selectedCaliberValue;
    _firearmId = widget.selectedFirearmId;
    _recipeId = widget.selectedLoadRecipeId;
  }

  int get _activeCount =>
      [_caliberValue, _firearmId, _recipeId].where((v) => v != null).length;

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
                  'Filter Sessions',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (_activeCount > 0)
                TextButton(
                  onPressed: () => setState(() {
                    _caliberValue = null;
                    _firearmId = null;
                    _recipeId = null;
                  }),
                  child: const Text('Clear all'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Caliber filter
                  if (widget.availableCalibers.isNotEmpty)
                    ExpansionTile(
                      leading: const Icon(Icons.straighten),
                      title: Text(
                        'Caliber',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: _caliberValue != null
                          ? Text(
                              _caliberValue!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            )
                          : null,
                      initiallyExpanded: _caliberValue != null,
                      children: [
                        RadioListTile<String?>(
                          title: const Text('Show all'),
                          value: null,
                          groupValue: _caliberValue,
                          onChanged: (v) => setState(() => _caliberValue = v),
                        ),
                        ...widget.availableCalibers.map(
                          (caliber) => RadioListTile<String?>(
                            title: Text(caliber),
                            value: caliber,
                            groupValue: _caliberValue,
                            onChanged: (v) => setState(() => _caliberValue = v),
                          ),
                        ),
                      ],
                    ),

                  // Firearm filter
                  if (widget.availableFirearms.isNotEmpty)
                    ExpansionTile(
                      leading: const Icon(Icons.gps_fixed),
                      title: Text(
                        'Firearm',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: _firearmId != null
                          ? Text(
                              widget.availableFirearms
                                  .firstWhere(
                                    (f) => f.id == _firearmId,
                                    orElse: () =>
                                        widget.availableFirearms.first,
                                  )
                                  .name,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            )
                          : null,
                      initiallyExpanded: _firearmId != null,
                      children: [
                        RadioListTile<String?>(
                          title: const Text('Show all'),
                          value: null,
                          groupValue: _firearmId,
                          onChanged: (v) => setState(() => _firearmId = v),
                        ),
                        ...widget.availableFirearms.map(
                          (firearm) => RadioListTile<String?>(
                            title: Text(firearm.name),
                            subtitle: Text(
                              '${firearm.caliber} • ${firearm.make} ${firearm.model}',
                            ),
                            value: firearm.id,
                            groupValue: _firearmId,
                            onChanged: (v) => setState(() => _firearmId = v),
                          ),
                        ),
                      ],
                    ),

                  // Load recipe filter
                  if (widget.availableRecipes.isNotEmpty)
                    ExpansionTile(
                      leading: const Icon(Icons.science),
                      title: Text(
                        'Load Recipe',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: _recipeId != null
                          ? Builder(
                              builder: (context) {
                                final recipe = widget.availableRecipes
                                    .firstWhere(
                                      (r) => r.id == _recipeId,
                                      orElse: () =>
                                          widget.availableRecipes.first,
                                    );
                                return Text(
                                  '${recipe.nickname} (${recipe.cartridge})',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                );
                              },
                            )
                          : null,
                      initiallyExpanded: _recipeId != null,
                      children: [
                        RadioListTile<String?>(
                          title: const Text('Show all'),
                          value: null,
                          groupValue: _recipeId,
                          onChanged: (v) => setState(() => _recipeId = v),
                        ),
                        ...widget.availableRecipes.map(
                          (recipe) => RadioListTile<String?>(
                            title: Text(recipe.nickname),
                            subtitle: Text(
                              '${recipe.cartridge} • ${recipe.bulletWeight.toStringAsFixed(1)}gr ${recipe.bulletType}',
                            ),
                            value: recipe.id,
                            groupValue: _recipeId,
                            onChanged: (v) => setState(() => _recipeId = v),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
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
                    widget.onApply(_caliberValue, _firearmId, _recipeId);
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
