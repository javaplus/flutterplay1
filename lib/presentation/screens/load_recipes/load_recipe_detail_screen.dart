import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/load_recipe_provider.dart';
import '../../../domain/entities/load_recipe.dart';
import 'add_edit_load_recipe_wizard.dart';

/// Detail screen for viewing a specific load recipe
class LoadRecipeDetailScreen extends ConsumerWidget {
  final String loadRecipeId;

  const LoadRecipeDetailScreen({super.key, required this.loadRecipeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadRecipeAsync = ref.watch(loadRecipeByIdProvider(loadRecipeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Load Recipe Details'),
        actions: [
          loadRecipeAsync.when(
            data: (loadRecipe) {
              if (loadRecipe == null) return const SizedBox.shrink();
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _navigateToEdit(context, ref, loadRecipe),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _confirmDelete(context, ref, loadRecipe),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: loadRecipeAsync.when(
        data: (loadRecipe) {
          if (loadRecipe == null) {
            return const Center(child: Text('Load recipe not found'));
          }
          return _buildDetailView(context, loadRecipe);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error loading load recipe',
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

  Widget _buildDetailView(BuildContext context, LoadRecipe loadRecipe) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              loadRecipe.cartridge,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Bullet Information
            _buildSection(context, 'Bullet', [
              _buildInfoRow(context, 'Weight', '${loadRecipe.bulletWeight}gr'),
              _buildInfoRow(context, 'Type', loadRecipe.bulletType),
            ]),
            const SizedBox(height: 24),

            // Powder Information
            _buildSection(context, 'Powder', [
              _buildInfoRow(context, 'Type', loadRecipe.powderType),
              _buildInfoRow(context, 'Charge', '${loadRecipe.powderCharge}gr'),
            ]),
            const SizedBox(height: 24),

            // Primer Information
            _buildSection(context, 'Primer', [
              _buildInfoRow(context, 'Type', loadRecipe.primerType),
            ]),
            const SizedBox(height: 24),

            // Brass Information
            _buildSection(context, 'Brass', [
              _buildInfoRow(context, 'Type', loadRecipe.brassType),
              if (loadRecipe.brassPrep != null &&
                  loadRecipe.brassPrep!.isNotEmpty)
                _buildInfoRow(context, 'Prep', loadRecipe.brassPrep!),
            ]),
            const SizedBox(height: 24),

            // Cartridge Dimensions
            _buildSection(context, 'Cartridge Dimensions', [
              _buildInfoRow(context, 'COAL', '${loadRecipe.coalLength}"'),
              if (loadRecipe.seatingDepth != null)
                _buildInfoRow(
                  context,
                  'Seating Depth',
                  '${loadRecipe.seatingDepth}"',
                ),
            ]),
            const SizedBox(height: 24),

            // Crimp
            if (loadRecipe.crimp != null && loadRecipe.crimp!.isNotEmpty) ...[
              _buildSection(context, 'Crimp', [
                _buildInfoRow(
                  context,
                  '',
                  loadRecipe.crimp!,
                  singleValue: true,
                ),
              ]),
              const SizedBox(height: 24),
            ],

            // Pressure Signs
            if (loadRecipe.pressureSigns.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildPressureSignsSection(context, loadRecipe.pressureSigns),
            ],

            // Notes
            if (loadRecipe.notes != null && loadRecipe.notes!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSection(context, 'Notes', [
                _buildInfoRow(
                  context,
                  '',
                  loadRecipe.notes!,
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
                dateFormat.format(loadRecipe.createdAt),
              ),
              _buildInfoRow(
                context,
                'Updated',
                dateFormat.format(loadRecipe.updatedAt),
              ),
            ]),
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
            width: 120,
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

  Widget _buildPressureSignsSection(
    BuildContext context,
    List<String> pressureSigns,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
            const SizedBox(width: 8),
            Text(
              'Pressure Signs',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.orange[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: pressureSigns.map((sign) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.orange[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        sign,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _navigateToEdit(
    BuildContext context,
    WidgetRef ref,
    LoadRecipe loadRecipe,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditLoadRecipeWizard(loadRecipe: loadRecipe),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    LoadRecipe loadRecipe,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Load Recipe'),
        content: Text(
          'Are you sure you want to delete "${loadRecipe.cartridge}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              final notifier = ref.read(loadRecipeNotifierProvider.notifier);
              await notifier.deleteLoadRecipe(loadRecipe.id);
              ref.invalidate(loadRecipesListProvider);
              if (context.mounted) {
                Navigator.pop(context); // Return to list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Load recipe deleted')),
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
}
