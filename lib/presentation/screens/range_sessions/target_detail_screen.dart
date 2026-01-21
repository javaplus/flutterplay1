import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/range_session_provider.dart';
import '../../providers/shot_velocity_provider.dart';
import '../../../domain/entities/target.dart';
import '../../../domain/entities/shot_velocity.dart';
import '../../../domain/entities/range_session.dart';
import 'add_target_screen.dart';
import 'chronograph_camera_screen.dart';

/// Detail screen for viewing a specific target with all shot velocities
class TargetDetailScreen extends ConsumerWidget {
  final Target target;
  final RangeSession session;

  const TargetDetailScreen({
    super.key,
    required this.target,
    required this.session,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('\n' + '=' * 80);
    debugPrint('🎯 TargetDetailScreen.build() called');
    debugPrint('   Target ID: ${target.id}');
    debugPrint('   Target distance: ${target.distance}');
    debugPrint('   Target shots: ${target.numberOfShots}');

    final velocitiesAsync = ref.watch(
      shotVelocitiesByTargetIdProvider(target.id),
    );

    debugPrint('📦 velocitiesAsync type: ${velocitiesAsync.runtimeType}');
    debugPrint('📦 velocitiesAsync.isLoading: ${velocitiesAsync.isLoading}');
    debugPrint('📦 velocitiesAsync.hasValue: ${velocitiesAsync.hasValue}');
    debugPrint('📦 velocitiesAsync.hasError: ${velocitiesAsync.hasError}');
    if (velocitiesAsync.hasValue) {
      debugPrint(
        '📦 velocitiesAsync.value.length: ${velocitiesAsync.value?.length}',
      );
    }
    if (velocitiesAsync.hasError) {
      debugPrint('❌ velocitiesAsync.error: ${velocitiesAsync.error}');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Target Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEdit(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Target Information
              _buildSection(context, 'Target Information', [
                _buildInfoRow(context, 'Distance', '${target.distance} yards'),
                _buildInfoRow(
                  context,
                  'Number of Shots',
                  '${target.numberOfShots}',
                ),
                if (target.groupSizeInches != null)
                  _buildInfoRow(
                    context,
                    'Group Size',
                    '${target.groupSizeInches!.toStringAsFixed(3)}"',
                  ),
                if (target.groupSizeMoa != null)
                  _buildInfoRow(
                    context,
                    'Group Size (MOA)',
                    '${target.groupSizeMoa!.toStringAsFixed(2)} MOA',
                  ),
              ]),
              const SizedBox(height: 24),

              // Velocity Statistics
              velocitiesAsync.when(
                data: (velocities) {
                  debugPrint('✅ velocitiesAsync.when(data) called');
                  debugPrint('   Velocities count: ${velocities.length}');
                  if (velocities.isNotEmpty) {
                    debugPrint(
                      '   First velocity: ${velocities.first.velocity} fps',
                    );
                    debugPrint(
                      '   First velocity targetId: ${velocities.first.targetId}',
                    );
                  }

                  if (velocities.isEmpty) {
                    debugPrint(
                      '⚠️ Velocities list is EMPTY, showing empty state',
                    );
                    return _buildEmptyVelocityState(context);
                  }

                  debugPrint('✅ Building velocity statistics section');
                  debugPrint('   target.avgVelocity: ${target.avgVelocity}');
                  debugPrint(
                    '   target.standardDeviation: ${target.standardDeviation}',
                  );
                  debugPrint(
                    '   target.extremeSpread: ${target.extremeSpread}',
                  );

                  return Column(
                    children: [
                      _buildSection(context, 'Velocity Statistics', [
                        if (target.avgVelocity != null)
                          _buildInfoRow(
                            context,
                            'Average Velocity',
                            '${target.avgVelocity!.toStringAsFixed(1)} fps',
                          ),
                        if (target.standardDeviation != null)
                          _buildInfoRow(
                            context,
                            'Standard Deviation',
                            '${target.standardDeviation!.toStringAsFixed(2)} fps',
                          ),
                        if (target.extremeSpread != null)
                          _buildInfoRow(
                            context,
                            'Extreme Spread',
                            '${target.extremeSpread!.toStringAsFixed(1)} fps',
                          ),
                        _buildInfoRow(
                          context,
                          'Recorded Shots',
                          '${velocities.length}',
                        ),
                      ]),
                      const SizedBox(height: 24),

                      // Individual Shot Velocities
                      _buildShotVelocitiesList(context, ref, velocities),
                    ],
                  );
                },
                loading: () {
                  debugPrint('⏳ velocitiesAsync.when(loading) called');
                  return const Center(child: CircularProgressIndicator());
                },
                error: (err, stack) {
                  debugPrint('❌ velocitiesAsync.when(error) called');
                  debugPrint('   Error: $err');
                  debugPrint('   Stack trace: $stack');
                  return _buildEmptyVelocityState(context);
                },
              ),

              // Notes
              if (target.notes != null && target.notes!.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildSection(context, 'Notes', [
                  _buildInfoRow(context, '', target.notes!, singleValue: true),
                ]),
              ],

              // Photo
              if (target.photoPath != null) ...[
                const SizedBox(height: 24),
                _buildSection(context, 'Photo', [
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Photo attached',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ]),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToRecordVelocities(context, ref),
        icon: const Icon(Icons.speed),
        label: const Text('Record Velocities'),
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
          width: double.infinity,
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
            width: 160,
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

  Widget _buildShotVelocitiesList(
    BuildContext context,
    WidgetRef ref,
    List<ShotVelocity> velocities,
  ) {
    debugPrint('\n🔍 _buildShotVelocitiesList called');
    debugPrint('   Velocities count: ${velocities.length}');

    if (velocities.isEmpty) {
      debugPrint('⚠️ Velocities list is EMPTY in _buildShotVelocitiesList');
    } else {
      debugPrint('✅ Building list of ${velocities.length} velocities');
      for (var i = 0; i < velocities.length; i++) {
        debugPrint(
          '   Shot ${i + 1}: ${velocities[i].velocity} fps (id: ${velocities[i].id})',
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Individual Shot Velocities (${velocities.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: velocities.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No shots to display'),
                )
              : Column(
                  children: List.generate(velocities.length, (index) {
                    final shot = velocities[index];
                    debugPrint(
                      '📊 Building shot #${index + 1}: ${shot.velocity} fps',
                    );

                    return Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            '${shot.velocity.toStringAsFixed(0)} fps',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            DateFormat(
                              'MMM dd, h:mm:ss a',
                            ).format(shot.timestamp),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Edit shot',
                                onPressed: () =>
                                    _showEditShotDialog(context, ref, shot),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                tooltip: 'Delete shot',
                                onPressed: () =>
                                    _confirmDeleteShot(context, ref, shot),
                              ),
                            ],
                          ),
                        ),
                        if (index < velocities.length - 1)
                          const Divider(height: 1),
                      ],
                    );
                  }),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyVelocityState(BuildContext context) {
    debugPrint('🔴 _buildEmptyVelocityState called - showing empty state UI');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.speed, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No velocity data recorded',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Use the button below to record shot velocities',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToEdit(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            AddTargetScreen(rangeSessionId: session.id, target: target),
      ),
    );
  }

  void _navigateToRecordVelocities(BuildContext context, WidgetRef ref) {
    debugPrint('\n📍 Navigating to ChronographCameraScreen');
    debugPrint('   Target ID: ${target.id}');
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => ChronographCameraScreen(targetId: target.id),
          ),
        )
        .then((_) {
          debugPrint(
            '\n🔄 Returned from ChronographCameraScreen - invalidating providers',
          );
          debugPrint(
            '   Invalidating shotVelocitiesByTargetIdProvider(${target.id})',
          );
          ref.invalidate(shotVelocitiesByTargetIdProvider(target.id));
          debugPrint(
            '   Invalidating targetsByRangeSessionIdProvider(${session.id})',
          );
          ref.invalidate(targetsByRangeSessionIdProvider(session.id));
          debugPrint('🔄 Providers invalidated, screen should rebuild');
        });
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Target'),
        content: const Text(
          'Are you sure you want to delete this target and all its shot data?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              final notifier = ref.read(targetNotifierProvider.notifier);
              await notifier.deleteTarget(target.id);
              ref.invalidate(
                targetsByRangeSessionIdProvider(target.rangeSessionId),
              );
              if (context.mounted) {
                Navigator.pop(context); // Return to range session
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

  void _showEditShotDialog(
    BuildContext context,
    WidgetRef ref,
    ShotVelocity shot,
  ) {
    final velocityController = TextEditingController(
      text: shot.velocity.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Shot Velocity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: velocityController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Velocity (fps)',
                border: OutlineInputBorder(),
                suffixText: 'fps',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Original: ${shot.velocity.toStringAsFixed(0)} fps',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              velocityController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newVelocity = double.tryParse(velocityController.text);
              velocityController.dispose();

              if (newVelocity == null || newVelocity <= 0) {
                Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid velocity'),
                    ),
                  );
                }
                return;
              }

              Navigator.pop(context);

              // Update the shot velocity
              final updatedShot = shot.copyWith(
                velocity: newVelocity,
                updatedAt: DateTime.now(),
              );

              final shotNotifier = ref.read(
                shotVelocityNotifierProvider.notifier,
              );
              await shotNotifier.updateShotVelocity(updatedShot);

              // Recalculate target statistics
              await ref
                  .read(targetNotifierProvider.notifier)
                  .recalcTargetVelocityStats(target.id);

              // Refresh the UI
              ref.invalidate(shotVelocitiesByTargetIdProvider(target.id));
              ref.invalidate(targetsByRangeSessionIdProvider(session.id));

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Shot velocity updated')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteShot(
    BuildContext context,
    WidgetRef ref,
    ShotVelocity shot,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shot'),
        content: const Text(
          'Remove this shot velocity from the target? This will update velocity statistics.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final shotNotifier = ref.read(
                shotVelocityNotifierProvider.notifier,
              );
              await shotNotifier.deleteShotVelocity(shot.id);

              await ref
                  .read(targetNotifierProvider.notifier)
                  .recalcTargetVelocityStats(target.id);

              ref.invalidate(shotVelocitiesByTargetIdProvider(target.id));
              ref.invalidate(targetsByRangeSessionIdProvider(session.id));

              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Shot removed')));
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
