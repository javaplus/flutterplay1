import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/range_session_provider.dart';
import '../../providers/firearm_provider.dart';
import '../../providers/load_recipe_provider.dart';
import '../../widgets/range_session_card.dart';
import 'range_session_detail_screen.dart';
import 'add_range_session_wizard.dart';

/// Main screen displaying the list of range sessions
class RangeSessionsListScreen extends ConsumerStatefulWidget {
  const RangeSessionsListScreen({super.key});

  @override
  ConsumerState<RangeSessionsListScreen> createState() =>
      _RangeSessionsListScreenState();
}

class _RangeSessionsListScreenState
    extends ConsumerState<RangeSessionsListScreen> {
  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(rangeSessionsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Range Sessions'), elevation: 2),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(rangeSessionsListProvider);
        },
        child: sessionsAsync.when(
          data: (sessions) {
            if (sessions.isEmpty) {
              return _buildEmptyState();
            }
            return ListView.builder(
              itemCount: sessions.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final session = sessions[index];

                // Fetch firearm and load recipe data
                final firearmAsync = ref.watch(
                  firearmByIdProvider(session.firearmId),
                );
                final loadRecipeAsync = ref.watch(
                  loadRecipeByIdProvider(session.loadRecipeId),
                );

                return firearmAsync.when(
                  data: (firearm) => loadRecipeAsync.when(
                    data: (loadRecipe) => RangeSessionCard(
                      session: session,
                      firearm: firearm,
                      loadRecipe: loadRecipe,
                      onTap: () => _navigateToDetail(session.id),
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
                Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
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
                  onPressed: () => ref.invalidate(rangeSessionsListProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddSession,
        icon: const Icon(Icons.add),
        label: const Text('Add Session'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.my_location, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            'No range sessions yet',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first range session to get started',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToAddSession,
            icon: const Icon(Icons.add),
            label: const Text('Add Session'),
          ),
        ],
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
