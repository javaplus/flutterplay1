import 'package:flutter/material.dart';
import '../../domain/entities/range_session.dart';
import '../../domain/entities/firearm.dart';
import '../../domain/entities/load_recipe.dart';
import '../../domain/entities/target.dart';

/// A card widget for displaying a range session in a list
class RangeSessionCard extends StatelessWidget {
  final RangeSession session;
  final Firearm? firearm;
  final LoadRecipe? loadRecipe;
  final List<Target>? targets;
  final VoidCallback onTap;

  const RangeSessionCard({
    super.key,
    required this.session,
    this.firearm,
    this.loadRecipe,
    this.targets,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with date
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(session.date),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Firearm info
              if (firearm != null) ...[
                Row(
                  children: [
                    Icon(Icons.gps_fixed, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${firearm!.name} (${firearm!.caliber})',
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Load recipe info
              if (loadRecipe != null) ...[
                Row(
                  children: [
                    Icon(Icons.science, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${loadRecipe!.bulletWeight}gr ${loadRecipe!.bulletType} • ${loadRecipe!.powderCharge}gr ${loadRecipe!.powderType}',
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Stats row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (targets != null && targets!.isNotEmpty)
                    ..._buildVelocityStats(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildVelocityStats(BuildContext context) {
    if (targets == null || targets!.isEmpty) return [];

    // Calculate total shots and aggregate velocity statistics
    int totalShots = 0;
    double totalAvgVelocity = 0;
    double totalStdDev = 0;
    int targetsWithVelocity = 0;

    for (final target in targets!) {
      totalShots += target.numberOfShots;
      if (target.avgVelocity != null) {
        totalAvgVelocity += target.avgVelocity!;
        targetsWithVelocity++;
      }
      if (target.standardDeviation != null) {
        totalStdDev += target.standardDeviation!;
      }
    }

    final List<Widget> stats = [];

    // Total shots
    if (totalShots > 0) {
      stats.add(_buildStatChip(context, Icons.speed, '$totalShots shots'));
    }

    // Average velocity
    if (targetsWithVelocity > 0) {
      final avgVelocity = totalAvgVelocity / targetsWithVelocity;
      stats.add(
        _buildStatChip(
          context,
          Icons.trending_up,
          '${avgVelocity.toStringAsFixed(0)} fps',
        ),
      );
    }

    // Standard deviation
    if (targetsWithVelocity > 0) {
      final avgStdDev = totalStdDev / targetsWithVelocity;
      stats.add(
        _buildStatChip(
          context,
          Icons.show_chart,
          'SD ${avgStdDev.toStringAsFixed(1)}',
        ),
      );
    }

    return stats;
  }

  Widget _buildStatChip(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
