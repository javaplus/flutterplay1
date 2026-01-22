import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/firearm_provider.dart';
import '../../../domain/entities/firearm.dart';
import 'add_edit_firearm_wizard.dart';

/// Detail screen for viewing a specific firearm
class FirearmDetailScreen extends ConsumerWidget {
  final String firearmId;

  const FirearmDetailScreen({super.key, required this.firearmId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firearmAsync = ref.watch(firearmByIdProvider(firearmId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Firearm Details'),
        actions: [
          firearmAsync.when(
            data: (firearm) {
              if (firearm == null) return const SizedBox.shrink();
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _navigateToEdit(context, ref, firearm),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _confirmDelete(context, ref, firearm),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: firearmAsync.when(
        data: (firearm) {
          if (firearm == null) {
            return const Center(child: Text('Firearm not found'));
          }
          return _buildDetailView(context, firearm);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error loading firearm',
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

  Widget _buildDetailView(BuildContext context, Firearm firearm) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo section
          if (firearm.photoPath != null && firearm.photoPath!.isNotEmpty)
            _buildPhotoSection(firearm.photoPath!),

          // Details section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  firearm.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Basic Info
                _buildSection(context, 'Basic Information', [
                  _buildInfoRow(context, 'Make', firearm.make),
                  _buildInfoRow(context, 'Model', firearm.model),
                  _buildInfoRow(context, 'Caliber', firearm.caliber),
                ]),
                const SizedBox(height: 24),

                // Barrel Info
                _buildSection(context, 'Barrel Specifications', [
                  _buildInfoRow(context, 'Length', '${firearm.barrelLength}"'),
                  _buildInfoRow(context, 'Twist Rate', firearm.barrelTwistRate),
                ]),
                const SizedBox(height: 24),

                // Usage Info
                _buildSection(context, 'Usage', [
                  _buildInfoRow(
                    context,
                    'Round Count',
                    '${firearm.roundCount}',
                  ),
                ]),

                // Optic Info
                if (firearm.opticInfo != null &&
                    firearm.opticInfo!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSection(context, 'Optic Information', [
                    _buildInfoRow(
                      context,
                      '',
                      firearm.opticInfo!,
                      singleValue: true,
                    ),
                  ]),
                ],

                // Notes
                if (firearm.notes != null && firearm.notes!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSection(context, 'Notes', [
                    _buildInfoRow(
                      context,
                      '',
                      firearm.notes!,
                      singleValue: true,
                    ),
                  ]),
                ],

                const SizedBox(height: 24),

                // Timestamps
                _buildSection(context, 'Record Information', [
                  _buildInfoRow(
                    context,
                    'Created',
                    _formatDate(firearm.createdAt),
                  ),
                  _buildInfoRow(
                    context,
                    'Last Updated',
                    _formatDate(firearm.updatedAt),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(String photoPath) {
    final file = File(photoPath);
    if (!file.existsSync()) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(color: Colors.grey[200]),
      child: Image.file(file, fit: BoxFit.cover),
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
        ...children,
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
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _navigateToEdit(
    BuildContext context,
    WidgetRef ref,
    Firearm firearm,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditFirearmWizard(firearm: firearm),
      ),
    );
    // Refresh after editing
    ref.invalidate(firearmByIdProvider(firearmId));
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Firearm firearm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Firearm'),
        content: Text('Are you sure you want to delete "${firearm.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _deleteFirearm(context, ref, firearm);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFirearm(
    BuildContext context,
    WidgetRef ref,
    Firearm firearm,
  ) async {
    final notifier = ref.read(firearmNotifierProvider.notifier);
    await notifier.deleteFirearm(firearm.id);

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${firearm.name} deleted')));
      Navigator.pop(context); // Return to list
    }
  }
}
