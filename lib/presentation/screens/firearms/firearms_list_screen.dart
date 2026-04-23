import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/firearm_provider.dart';
import '../../widgets/firearm_card.dart';
import 'firearm_detail_screen.dart';
import 'add_edit_firearm_wizard.dart';
import '../range_sessions/add_range_session_wizard.dart';

/// Main screen displaying the list of firearms
class FirearmsListScreen extends ConsumerStatefulWidget {
  const FirearmsListScreen({super.key});

  @override
  ConsumerState<FirearmsListScreen> createState() => _FirearmsListScreenState();
}

class _FirearmsListScreenState extends ConsumerState<FirearmsListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Set<String> _selectedCalibers = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Always watch the full list to derive available calibers
    final allFirearmsAsync = ref.watch(firearmsListProvider);
    final firearmsAsync = _searchQuery.isEmpty
        ? allFirearmsAsync
        : ref.watch(firearmSearchProvider(_searchQuery));

    // Derive sorted distinct calibers from all firearms
    final allCalibers = allFirearmsAsync.maybeWhen(
      data: (list) => (list.map((f) => f.caliber).toSet().toList()..sort()),
      orElse: () => <String>[],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Firearms'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          Badge(
            isLabelVisible: _selectedCalibers.isNotEmpty,
            label: Text('${_selectedCalibers.length}'),
            child: IconButton(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filter by caliber',
              onPressed: allCalibers.isEmpty
                  ? null
                  : () => _showCaliberFilter(allCalibers),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Active filter chip row
          if (_selectedCalibers.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  ..._selectedCalibers.map(
                    (caliber) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(caliber),
                        selected: true,
                        onSelected: (_) =>
                            setState(() => _selectedCalibers.remove(caliber)),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () =>
                            setState(() => _selectedCalibers.remove(caliber)),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selectedCalibers.clear()),
                    child: const Text('Clear all'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(firearmsListProvider);
              },
              child: firearmsAsync.when(
                data: (firearms) {
                  // Apply caliber filter client-side
                  final filtered = _selectedCalibers.isEmpty
                      ? firearms
                      : firearms
                            .where((f) => _selectedCalibers.contains(f.caliber))
                            .toList();

                  if (filtered.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.builder(
                    itemCount: filtered.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final firearm = filtered[index];
                      return FirearmCard(
                        firearm: firearm,
                        onTap: () => _navigateToDetail(firearm.id),
                        onStartRangeSession: () =>
                            _navigateToRangeSession(firearm.id),
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
                        'Error loading firearms',
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
                        onPressed: () => ref.invalidate(firearmsListProvider),
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
        onPressed: _navigateToAddFirearm,
        icon: const Icon(Icons.add),
        label: const Text('Add Firearm'),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isFiltered = _selectedCalibers.isNotEmpty;
    final String title;
    final String subtitle;
    if (isFiltered) {
      title = 'No firearms match the selected caliber(s)';
      subtitle = 'Try adjusting or clearing the caliber filter';
    } else if (_searchQuery.isNotEmpty) {
      title = 'No firearms found';
      subtitle = 'Try a different search term';
    } else {
      title = 'No firearms yet';
      subtitle = 'Add your first firearm to get started';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 100, color: Colors.grey[300]),
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
              onPressed: () => setState(() => _selectedCalibers.clear()),
              icon: const Icon(Icons.filter_list_off),
              label: const Text('Clear Filter'),
            ),
          ] else if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToAddFirearm,
              icon: const Icon(Icons.add),
              label: const Text('Add Firearm'),
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
        title: const Text('Search Firearms'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Enter name, make, model, or caliber',
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
              _searchController.clear();
              setState(() {
                _searchQuery = '';
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

  void _navigateToDetail(String firearmId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FirearmDetailScreen(firearmId: firearmId),
      ),
    );
    // Refresh list after returning from detail screen
    ref.invalidate(firearmsListProvider);
  }

  void _navigateToRangeSession(String firearmId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            AddRangeSessionWizard(initialFirearmId: firearmId),
      ),
    );
  }

  void _navigateToAddFirearm() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditFirearmWizard()),
    );
    // Refresh list after returning
    ref.invalidate(firearmsListProvider);
  }

  void _showCaliberFilter(List<String> allCalibers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => _CaliberFilterSheet(
        allCalibers: allCalibers,
        initialSelection: Set.from(_selectedCalibers),
        onApply: (selected) => setState(() => _selectedCalibers = selected),
      ),
    );
  }
}

/// Bottom sheet for selecting caliber filters
class _CaliberFilterSheet extends StatefulWidget {
  final List<String> allCalibers;
  final Set<String> initialSelection;
  final void Function(Set<String>) onApply;

  const _CaliberFilterSheet({
    required this.allCalibers,
    required this.initialSelection,
    required this.onApply,
  });

  @override
  State<_CaliberFilterSheet> createState() => _CaliberFilterSheetState();
}

class _CaliberFilterSheetState extends State<_CaliberFilterSheet> {
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
                  'Filter by Caliber',
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

          // Caliber checkboxes
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: ListView(
              shrinkWrap: true,
              children: widget.allCalibers.map((caliber) {
                return CheckboxListTile(
                  title: Text(caliber),
                  value: _selection.contains(caliber),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selection.add(caliber);
                      } else {
                        _selection.remove(caliber);
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
