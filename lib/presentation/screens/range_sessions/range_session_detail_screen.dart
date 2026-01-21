import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/range_session_provider.dart';
import '../../providers/firearm_provider.dart';
import '../../providers/load_recipe_provider.dart';
import '../../providers/shot_velocity_provider.dart';
import '../../../domain/entities/range_session.dart';
import '../../../domain/entities/target.dart';
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

            // Overall Velocity Statistics
            targetsAsync.when(
              data: (targets) {
                return _buildOverallVelocityStats(context, ref, targets);
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

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
                        (target) => _TargetCard(
                          target: target,
                          session: session,
                          onTap: () =>
                              _navigateToEditTarget(context, session, target),
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

  Widget _buildOverallVelocityStats(
    BuildContext context,
    WidgetRef ref,
    List<Target> targets,
  ) {
    if (targets.isEmpty) return const SizedBox.shrink();

    // Collect all velocities from all targets
    List<double> allVelocities = [];
    int totalShots = 0;

    for (final target in targets) {
      final velocitiesAsync = ref.watch(
        shotVelocitiesByTargetIdProvider(target.id),
      );
      velocitiesAsync.whenData((velocities) {
        allVelocities.addAll(velocities.map((v) => v.velocity));
        totalShots += velocities.length;
      });
    }

    if (allVelocities.isEmpty) return const SizedBox.shrink();

    // Calculate overall statistics
    final avgVelocity =
        allVelocities.reduce((a, b) => a + b) / allVelocities.length;
    final minVelocity = allVelocities.reduce((a, b) => a < b ? a : b);
    final maxVelocity = allVelocities.reduce((a, b) => a > b ? a : b);
    final extremeSpread = maxVelocity - minVelocity;

    // Calculate standard deviation
    double calculateSD() {
      if (allVelocities.length < 2) return 0.0;
      final sumSquaredDiff = allVelocities
          .map((v) => (v - avgVelocity) * (v - avgVelocity))
          .reduce((a, b) => a + b);
      final variance = sumSquaredDiff / (allVelocities.length - 1);
      return variance.sqrt();
    }

    final standardDeviation = calculateSD();

    return Column(
      children: [
        _buildSection(context, 'Overall Velocity Statistics', [
          _buildInfoRow(context, 'Total Shots', '$totalShots'),
          _buildInfoRow(
            context,
            'Average Velocity',
            '${avgVelocity.toStringAsFixed(1)} fps',
          ),
          _buildInfoRow(
            context,
            'Standard Deviation',
            '${standardDeviation.toStringAsFixed(2)} fps',
          ),
          _buildInfoRow(
            context,
            'Extreme Spread',
            '${extremeSpread.toStringAsFixed(1)} fps',
          ),
          _buildInfoRow(
            context,
            'Min Velocity',
            '${minVelocity.toStringAsFixed(0)} fps',
          ),
          _buildInfoRow(
            context,
            'Max Velocity',
            '${maxVelocity.toStringAsFixed(0)} fps',
          ),
        ]),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Reusable target card widget with velocity information
class _TargetCard extends ConsumerWidget {
  final Target target;
  final RangeSession session;
  final VoidCallback onTap;

  const _TargetCard({
    required this.target,
    required this.session,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final velocitiesAsync = ref.watch(
      shotVelocitiesByTargetIdProvider(target.id),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with basic info and menu
              Row(
                children: [
                  Icon(
                    Icons.filter_center_focus,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: velocitiesAsync.when(
                      data: (velocities) {
                        final shotCount = velocities.length;
                        return Text(
                          '${target.distance} yards • ${shotCount > 0 ? shotCount : target.numberOfShots} shots',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        );
                      },
                      loading: () => Text(
                        '${target.distance} yards • ${target.numberOfShots} shots',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      error: (_, __) => Text(
                        '${target.distance} yards • ${target.numberOfShots} shots',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Target Statistics Section
              velocitiesAsync.when(
                data: (velocities) {
                  return _buildTargetStatistics(context, target, velocities);
                },
                loading: () => _buildLoadingStatistics(context),
                error: (_, __) => _buildEmptyStatistics(context),
              ),

              // Notes
              if (target.notes != null && target.notes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  target.notes!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],

              // Photo indicator
              if (target.photoPath != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.photo, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Photo attached',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetStatistics(
    BuildContext context,
    Target target,
    List<dynamic> velocities,
  ) {
    // Calculate statistics from velocities
    final List<double> velocityValues = velocities
        .map((v) => v.velocity as double)
        .toList();

    if (velocityValues.isEmpty) {
      return _buildEmptyStatistics(context);
    }

    final avgVelocity =
        velocityValues.reduce((a, b) => a + b) / velocityValues.length;
    final minVelocity = velocityValues.reduce((a, b) => a < b ? a : b);
    final maxVelocity = velocityValues.reduce((a, b) => a > b ? a : b);
    final extremeSpread = maxVelocity - minVelocity;

    double calculateSD() {
      if (velocityValues.length < 2) return 0.0;
      final sumSquaredDiff = velocityValues
          .map((v) => (v - avgVelocity) * (v - avgVelocity))
          .reduce((a, b) => a + b);
      final variance = sumSquaredDiff / (velocityValues.length - 1);
      return variance.sqrt();
    }

    final standardDeviation = calculateSD();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Target Statistics',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue[900],
            ),
          ),
          const SizedBox(height: 8),
          _buildStatRow(context, 'Shots Recorded', '${velocityValues.length}'),
          if (target.groupSizeInches != null)
            _buildStatRow(
              context,
              'Group Size',
              '${target.groupSizeInches!.toStringAsFixed(3)}"',
            ),
          if (target.groupSizeMoa != null)
            _buildStatRow(
              context,
              'Group Size (MOA)',
              '${target.groupSizeMoa!.toStringAsFixed(2)} MOA',
            ),
          const Divider(height: 16),
          Text(
            'Velocity Data',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.blue[900],
            ),
          ),
          const SizedBox(height: 4),
          _buildStatRow(
            context,
            'Average',
            '${avgVelocity.toStringAsFixed(1)} fps',
          ),
          _buildStatRow(
            context,
            'Std Deviation',
            '${standardDeviation.toStringAsFixed(2)} fps',
          ),
          _buildStatRow(
            context,
            'Extreme Spread',
            '${extremeSpread.toStringAsFixed(1)} fps',
          ),
          _buildStatRow(
            context,
            'Min / Max',
            '${minVelocity.toStringAsFixed(0)} / ${maxVelocity.toStringAsFixed(0)} fps',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStatistics(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.speed_outlined, size: 20, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'No velocity data recorded yet',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStatistics(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Center(
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// Helper extension for better sqrt calculation
extension DoubleExt on double {
  double sqrt() {
    if (this <= 0) return 0.0;
    double x = this;
    double y = 1.0;
    double e = 0.000001;
    while (x - y > e) {
      x = (x + y) / 2;
      y = this / x;
    }
    return x;
  }
}
