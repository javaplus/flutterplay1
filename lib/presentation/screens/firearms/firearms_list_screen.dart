import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/firearm_provider.dart';
import '../../widgets/firearm_card.dart';
import 'firearm_detail_screen.dart';
import 'add_edit_firearm_wizard.dart';

/// Main screen displaying the list of firearms
class FirearmsListScreen extends ConsumerStatefulWidget {
  const FirearmsListScreen({super.key});

  @override
  ConsumerState<FirearmsListScreen> createState() => _FirearmsListScreenState();
}

class _FirearmsListScreenState extends ConsumerState<FirearmsListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firearmsAsync = _searchQuery.isEmpty
        ? ref.watch(firearmsListProvider)
        : ref.watch(firearmSearchProvider(_searchQuery));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Firearms'),
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
          ref.invalidate(firearmsListProvider);
        },
        child: firearmsAsync.when(
          data: (firearms) {
            if (firearms.isEmpty) {
              return _buildEmptyState();
            }
            return ListView.builder(
              itemCount: firearms.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final firearm = firearms[index];
                return FirearmCard(
                  firearm: firearm,
                  onTap: () => _navigateToDetail(firearm.id),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddFirearm,
        icon: const Icon(Icons.add),
        label: const Text('Add Firearm'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isEmpty ? 'No firearms yet' : 'No firearms found',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Add your first firearm to get started'
                : 'Try a different search term',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
          if (_searchQuery.isEmpty) ...[
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

  void _navigateToAddFirearm() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditFirearmWizard()),
    );
    // Refresh list after returning
    ref.invalidate(firearmsListProvider);
  }
}
