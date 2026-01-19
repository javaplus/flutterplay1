import 'package:flutter/material.dart';
import '../../domain/entities/load_recipe.dart';

/// A card widget for displaying a load recipe in a list
class LoadRecipeCard extends StatelessWidget {
  final LoadRecipe loadRecipe;
  final VoidCallback onTap;

  const LoadRecipeCard({
    super.key,
    required this.loadRecipe,
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
              // Header row with cartridge and bullet weight
              Row(
                children: [
                  Expanded(
                    child: Text(
                      loadRecipe.cartridge,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${loadRecipe.bulletWeight.toStringAsFixed(1)}gr',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Bullet type
              Text(
                loadRecipe.bulletType,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),

              // Powder info
              Row(
                children: [
                  Icon(Icons.science, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${loadRecipe.powderType} • ${loadRecipe.powderCharge.toStringAsFixed(1)}gr',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Brass and primer info
              Row(
                children: [
                  Icon(Icons.hardware, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${loadRecipe.brassType} • ${loadRecipe.primerType}',
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Pressure signs warning (if any)
              if (loadRecipe.pressureSigns.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber,
                        size: 16,
                        color: Colors.orange[800],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${loadRecipe.pressureSigns.length} pressure sign(s)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
