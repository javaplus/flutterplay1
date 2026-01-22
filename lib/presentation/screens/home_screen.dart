import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/firearm_provider.dart';
import '../providers/load_recipe_provider.dart';
import '../providers/range_session_provider.dart';
import 'firearms/firearms_list_screen.dart';
import 'load_recipes/load_recipes_list_screen.dart';
import 'range_sessions/range_sessions_list_screen.dart';

/// Main home screen with navigation to different sections
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = 'v${packageInfo.version}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final firearmsAsync = ref.watch(firearmsListProvider);
    final loadRecipesAsync = ref.watch(loadRecipesListProvider);
    final rangeSessionsAsync = ref.watch(rangeSessionsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Flexible(
              child: Text(
                'Reloading Companion',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_version.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _version,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        elevation: 2,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              Text(
                'Welcome!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage your firearms and load recipes',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),

              // Firearms Card
              _buildSectionCard(
                context: context,
                title: 'Firearms',
                description: 'Manage your firearm profiles',
                icon: Icons.gps_fixed,
                iconColor: Colors.blue,
                count: firearmsAsync.maybeWhen(
                  data: (firearms) => firearms.length,
                  orElse: () => null,
                ),
                onTap: () => _navigateToFirearms(context),
              ),

              const SizedBox(height: 16),

              // Load Recipes Card
              _buildSectionCard(
                context: context,
                title: 'Load Recipes',
                description: 'Manage your reloading data',
                icon: Icons.science,
                iconColor: Colors.orange,
                count: loadRecipesAsync.maybeWhen(
                  data: (recipes) => recipes.length,
                  orElse: () => null,
                ),
                onTap: () => _navigateToLoadRecipes(context),
              ),

              const SizedBox(height: 16),

              // Range Sessions Card
              _buildSectionCard(
                context: context,
                title: 'Range Sessions',
                description: 'Track your shooting sessions',
                icon: Icons.my_location,
                iconColor: Colors.green,
                count: rangeSessionsAsync.maybeWhen(
                  data: (sessions) => sessions.length,
                  orElse: () => null,
                ),
                onTap: () => _navigateToRangeSessions(context),
              ),

              const SizedBox(height: 16),

              _buildComingSoonCard(
                context: context,
                title: 'Component Inventory',
                description: 'Track brass, bullets, powder, and primers',
                icon: Icons.inventory_2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    int? count,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: iconColor),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (count != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: iconColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              count.toString(),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComingSoonCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Card(
      child: Opacity(
        opacity: 0.5,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: Colors.grey[400]),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Coming Soon',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToFirearms(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const FirearmsListScreen()));
  }

  void _navigateToLoadRecipes(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const LoadRecipesListScreen()),
    );
  }

  void _navigateToRangeSessions(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const RangeSessionsListScreen()),
    );
  }
}
