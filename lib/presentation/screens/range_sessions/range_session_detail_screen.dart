import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/range_session_provider.dart';
import '../../providers/firearm_provider.dart';
import '../../providers/load_recipe_provider.dart';
import '../../../domain/entities/range_session.dart';
import 'add_range_session_wizard.dart';
import 'add_target_screen.dart';

/// Detail screen for viewing a specific range session
class RangeSessionDetailScreen extends ConsumerWidget {
  final String sessionId;

  const RangeSessionDetailScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(rangeSessionByIdProvider(sessionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Range Session Details'),
        actions: [
          sessionAsync.when(
            data: (session) {
              if (session == null) return const SizedBox.shrink();
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _navigateToEdit(context, ref, session),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _confirmDelete(context, ref, session),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: sessionAsync.when(
        data: (session) {
          if (session == null) {
            return const Center(child: Text('Range session not found'));
          }
          return _buildDetailView(context, ref, session);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error loading range session',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(error.toString()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailView(
    BuildContext context,
    WidgetRef ref,
    RangeSession session,
  ) {
    final dateFormat = DateFormat('EEEE, MMM dd, yyyy');
    final firearmAsync = ref.watch(firearmByIdProvider(session.firearmId));
    final loadRecipeAsync = ref.watch(
      loadRecipeByIdProvider(session.loadRecipeId),
    );
    final targetsAsync = ref.watch(targetsByRangeSessionIdProvider(session.id));

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session Information
            _buildSection(context, 'Session Information', [
              _buildInfoRow(context, 'Date', dateFormat.format(session.date)),
              _buildInfoRow(context, 'Rounds Fired', '${session.roundsFired}'),
              if (session.weather != null && session.weather!.isNotEmpty)
                _buildInfoRow(context, 'Weather', session.weather!),
            ]),
            const SizedBox(height: 24),

            // Firearm Information
            firearmAsync.when(
              data: (firearm) {
                if (firearm == null) return const SizedBox.shrink();
                return Column(
                  children: [
                    _buildSection(context, 'Firearm', [
                      _buildInfoRow(context, 'Name', firearm.name),
                      _buildInfoRow(
                        context,
                        'Make/Model',
                        '${firearm.make} ${firearm.model}',
                      ),
                      _buildInfoRow(context, 'Caliber', firearm.caliber),
                    ]),
                    const SizedBox(height: 24),
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Load Recipe Information
            loadRecipeAsync.when(
              data: (loadRecipe) {
                if (loadRecipe == null) return const SizedBox.shrink();
                return Column(
                  children: [
                    _buildSection(context, 'Load Recipe', [
                      _buildInfoRow(context, 'Cartridge', loadRecipe.cartridge),
                      _buildInfoRow(
                        context,
                        'Bullet',
                        '${loadRecipe.bulletWeight}gr ${loadRecipe.bulletType}',
                      ),
                      _buildInfoRow(
                        context,
                        'Powder',
                        '${loadRecipe.powderType} - ${loadRecipe.powderCharge}gr',
                      ),
                      _buildInfoRow(context, 'Primer', loadRecipe.primerType),
                    ]),
                    const SizedBox(height: 24),
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Chronograph Data
            if (session.avgVelocity != null ||
                session.standardDeviation != null ||
                session.extremeSpread != null) ...[
              _buildSection(context, 'Chronograph Data', [
                if (session.avgVelocity != null)
                  _buildInfoRow(
                    context,
                    'Avg Velocity',
                    '${session.avgVelocity!.toStringAsFixed(1)} fps',
                  ),
                if (session.standardDeviation != null)
                  _buildInfoRow(
                    context,
                    'Std Deviation (SD)',
                    '${session.standardDeviation!.toStringAsFixed(2)} fps',
                  ),
                if (session.extremeSpread != null)
                  _buildInfoRow(
                    context,
                    'Extreme Spread (ES)',
                    '${session.extremeSpread!.toStringAsFixed(1)} fps',
                  ),
              ]),
              const SizedBox(height: 24),
            ],

            // Targets
            targetsAsync.when(
              data: (targets) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Targets (${targets.length})',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              _navigateToAddTarget(context, session),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Target'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (targets.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: Text('No targets recorded yet')),
                        ),
                      )
                    else
                      ...targets.map(
                        (target) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.filter_center_focus,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${target.distance} yards • ${target.numberOfShots} shots',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                    PopupMenuButton(
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit),
                                              SizedBox(width: 8),
                                              Text('Edit'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _navigateToEditTarget(
                                            context,
                                            session,
                                            target,
                                          );
                                        } else if (value == 'delete') {
                                          _confirmDeleteTarget(
                                            context,
                                            ref,
                                            target,
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                if (target.groupSizeInches != null ||
                                    target.groupSizeMoa != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Group: ${target.groupSizeInches != null ? "${target.groupSizeInches!.toStringAsFixed(3)}\"" : ""} ${target.groupSizeMoa != null ? "(${target.groupSizeMoa!.toStringAsFixed(2)} MOA)" : ""}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                                if (target.notes != null &&
                                    target.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    target.notes!,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                ],
                                if (target.photoPath != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.photo,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Photo attached',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Notes
            if (session.notes != null && session.notes!.isNotEmpty) ...[
              _buildSection(context, 'Notes', [
                _buildInfoRow(context, '', session.notes!, singleValue: true),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool singleValue = false,
  }) {
    if (singleValue) {
      return Text(value, style: Theme.of(context).textTheme.bodyMedium);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  void _navigateToEdit(
    BuildContext context,
    WidgetRef ref,
    RangeSession session,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddRangeSessionWizard(session: session),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    RangeSession session,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Range Session'),
        content: const Text(
          'Are you sure you want to delete this range session and all its targets?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              final notifier = ref.read(rangeSessionNotifierProvider.notifier);
              await notifier.deleteRangeSession(session.id);
              ref.invalidate(rangeSessionsListProvider);
              if (context.mounted) {
                Navigator.pop(context); // Return to list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Range session deleted')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddTarget(BuildContext context, RangeSession session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddTargetScreen(rangeSessionId: session.id),
      ),
    );
  }

  void _navigateToEditTarget(
    BuildContext context,
    RangeSession session,
    target,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            AddTargetScreen(rangeSessionId: session.id, target: target),
      ),
    );
  }

  void _confirmDeleteTarget(BuildContext context, WidgetRef ref, target) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Target'),
        content: const Text('Are you sure you want to delete this target?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final notifier = ref.read(targetNotifierProvider.notifier);
              await notifier.deleteTarget(target.id);
              ref.invalidate(
                targetsByRangeSessionIdProvider(target.rangeSessionId),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Target deleted')));
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
