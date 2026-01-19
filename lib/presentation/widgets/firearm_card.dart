import 'dart:io';
import 'package:flutter/material.dart';
import '../../../domain/entities/firearm.dart';

/// Card widget for displaying a firearm in a list
class FirearmCard extends StatelessWidget {
  final Firearm firearm;
  final VoidCallback onTap;

  const FirearmCard({super.key, required this.firearm, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Firearm photo or placeholder
              _buildPhoto(),
              const SizedBox(width: 16),
              // Firearm details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name (nickname)
                    Text(
                      firearm.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Make and Model
                    Text(
                      '${firearm.make} ${firearm.model}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    // Caliber with icon
                    Row(
                      children: [
                        Icon(
                          Icons.adjust,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          firearm.caliber,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Barrel length and twist rate
                    Text(
                      'Barrel: ${firearm.barrelLength}" • ${firearm.barrelTwistRate}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (firearm.roundCount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Round count: ${firearm.roundCount}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Arrow icon
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto() {
    if (firearm.photoPath != null && firearm.photoPath!.isNotEmpty) {
      final file = File(firearm.photoPath!);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(file, width: 80, height: 80, fit: BoxFit.cover),
        );
      }
    }

    // Placeholder icon
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.photo_camera, size: 40, color: Colors.grey[400]),
    );
  }
}
