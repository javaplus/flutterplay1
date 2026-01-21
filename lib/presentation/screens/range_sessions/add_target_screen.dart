import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/target.dart';
import '../../../domain/entities/shot_velocity.dart';
import '../../providers/range_session_provider.dart';
import '../../providers/shot_velocity_provider.dart';
import 'chronograph_camera_screen.dart';
import 'target_photo_analysis_screen.dart';

/// Screen for adding or editing a target
class AddTargetScreen extends ConsumerStatefulWidget {
  final String rangeSessionId;
  final Target? target;

  const AddTargetScreen({super.key, required this.rangeSessionId, this.target});

  @override
  ConsumerState<AddTargetScreen> createState() => _AddTargetScreenState();
}

class _AddTargetScreenState extends ConsumerState<AddTargetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _distanceController = TextEditingController();
  final _groupInchesController = TextEditingController();
  final _notesController = TextEditingController();

  String? _photoPath;
  bool _groupSizeFromAnalysis = false;
  bool _isVelocityListExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadTargetData();
  }

  void _loadTargetData() {
    if (widget.target != null) {
      final target = widget.target!;
      _distanceController.text = target.distance.toString();
      _groupInchesController.text = target.groupSizeInches?.toString() ?? '';
      _notesController.text = target.notes ?? '';
      _photoPath = target.photoPath;
    }
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _groupInchesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.target != null;

    // Watch shot velocities if editing to show count
    final velocitiesAsync = isEditing
        ? ref.watch(shotVelocitiesByTargetIdProvider(widget.target!.id))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Target' : 'Add Target'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete Target',
              onPressed: _confirmDelete,
            ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: isEditing ? 'Update Target' : 'Save Target',
            onPressed: _saveTarget,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Distance
              TextFormField(
                controller: _distanceController,
                decoration: const InputDecoration(
                  labelText: 'Distance (yards) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.straighten),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter distance';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Velocity statistics display (read-only, auto-populated from velocities)
              if (isEditing)
                velocitiesAsync?.when(
                      data: (velocities) {
                        if (velocities.isEmpty) {
                          return Card(
                            color: Colors.orange[50],
                            child: const ListTile(
                              leading: Icon(
                                Icons.info_outline,
                                color: Colors.orange,
                              ),
                              title: Text(
                                'No velocities recorded yet',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Use the "Record Shot Velocities" button below to capture velocities',
                              ),
                            ),
                          );
                        }

                        // Calculate statistics
                        final velocityValues = velocities
                            .map((v) => v.velocity)
                            .toList();
                        final avg =
                            velocityValues.reduce((a, b) => a + b) /
                            velocityValues.length;
                        final max = velocityValues.reduce(
                          (a, b) => a > b ? a : b,
                        );
                        final min = velocityValues.reduce(
                          (a, b) => a < b ? a : b,
                        );
                        final extremeSpread = max - min;

                        // Calculate standard deviation
                        double stdDev = 0;
                        if (velocityValues.length > 1) {
                          final variance =
                              velocityValues
                                  .map((v) => (v - avg) * (v - avg))
                                  .reduce((a, b) => a + b) /
                              velocityValues.length;
                          stdDev = sqrt(variance);
                        }

                        return Card(
                          color: Colors.green[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.speed,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Velocity Statistics',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[900],
                                          ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),
                                _buildStatRow(
                                  'Recorded Shots',
                                  '${velocities.length}',
                                ),
                                _buildStatRow(
                                  'Average Velocity',
                                  '${avg.toStringAsFixed(1)} fps',
                                ),
                                _buildStatRow(
                                  'Standard Deviation',
                                  '${stdDev.toStringAsFixed(1)} fps',
                                ),
                                _buildStatRow(
                                  'Extreme Spread',
                                  '${extremeSpread.toStringAsFixed(1)} fps',
                                ),
                                _buildStatRow(
                                  'Min Velocity',
                                  '${min.toStringAsFixed(1)} fps',
                                ),
                                _buildStatRow(
                                  'Max Velocity',
                                  '${max.toStringAsFixed(1)} fps',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const SizedBox.shrink(),
                    ) ??
                    const SizedBox.shrink(),

              if (isEditing) const SizedBox(height: 16),

              Text(
                'Group Size',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Group size in inches
              TextFormField(
                controller: _groupInchesController,
                decoration: const InputDecoration(
                  labelText: 'Group Size (inches) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.straighten),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter group size';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Photo
              Text(
                'Target Photo (Optional)',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              if (_photoPath != null) ...[
                Card(
                  child: Column(
                    children: [
                      // Display the photo
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                        child: Image.file(
                          File(_photoPath!),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.photo),
                        title: const Text('Target photo'),
                        subtitle: _groupSizeFromAnalysis
                            ? const Text('Group size calculated from photo')
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_groupSizeFromAnalysis)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _photoPath = null;
                                  _groupSizeFromAnalysis = false;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickPhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: Text(
                        _photoPath == null ? 'Take Photo' : 'Change Photo',
                      ),
                    ),
                  ),
                  if (_photoPath != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _analyzePhoto,
                        icon: const Icon(Icons.analytics),
                        label: const Text('Analyze'),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              // Chronograph velocities
              Text(
                'Velocity Recording (Optional)',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: _openChronographCamera,
                icon: const Icon(Icons.speed),
                label: const Text('Record Shot Velocities'),
              ),
              const SizedBox(height: 8),

              Text(
                'Use your camera to automatically capture velocities from a chronograph display',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),

              // Individual Shot Velocities (collapsible, only when editing)
              if (isEditing && velocitiesAsync != null) ...[
                velocitiesAsync.when(
                  data: (velocities) {
                    if (velocities.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return _buildCollapsibleVelocityList(
                      context,
                      ref,
                      velocities,
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),
              ],

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Observations about this target...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              const SizedBox(
                height: 100,
              ), // Extra padding for bottom navigation
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      // Copy to permanent storage
      final permanentPath = await _savePhotoToStorage(photo.path);
      setState(() {
        _photoPath = permanentPath;
        _groupSizeFromAnalysis = false;
      });
    }
  }

  Future<String> _savePhotoToStorage(String tempPath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final targetPhotosDir = Directory('${appDir.path}/target_photos');
    if (!await targetPhotosDir.exists()) {
      await targetPhotosDir.create(recursive: true);
    }

    final fileName = '${const Uuid().v4()}${path.extension(tempPath)}';
    final permanentPath = '${targetPhotosDir.path}/$fileName';
    final tempFile = File(tempPath);
    await tempFile.copy(permanentPath);

    return permanentPath;
  }

  Future<void> _analyzePhoto() async {
    if (_photoPath == null) return;

    final result = await Navigator.push<TargetAnalysisResult>(
      context,
      MaterialPageRoute(
        builder: (context) => TargetPhotoAnalysisScreen(
          photoPath: _photoPath!,
          onAnalysisComplete: (result) {
            // This callback is called in the analysis screen
          },
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _groupInchesController.text = result.groupSizeInches.toStringAsFixed(3);
        _groupSizeFromAnalysis = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Analysis complete: ${result.numberOfShots} shots, '
            '${result.groupSizeInches.toStringAsFixed(3)}" group',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openChronographCamera() async {
    // If we're editing an existing target, we already have a targetId
    if (widget.target != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ChronographCameraScreen(targetId: widget.target!.id),
        ),
      );
      // Invalidate providers to refresh velocity statistics
      if (mounted) {
        ref.invalidate(shotVelocitiesByTargetIdProvider(widget.target!.id));
        ref.invalidate(targetsByRangeSessionIdProvider(widget.rangeSessionId));
      }
      return;
    }

    // For new targets, validate form first
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill in required fields before recording velocities',
          ),
        ),
      );
      return;
    }

    // Save the target first with initial shot count of 0
    final now = DateTime.now();
    final targetId = const Uuid().v4();
    final target = Target(
      id: targetId,
      rangeSessionId: widget.rangeSessionId,
      distance: double.parse(_distanceController.text),
      numberOfShots: 0, // Will be updated when velocities are recorded
      groupSizeInches: _groupInchesController.text.isEmpty
          ? null
          : double.tryParse(_groupInchesController.text),
      photoPath: _photoPath,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: now,
      updatedAt: now,
    );

    final notifier = ref.read(targetNotifierProvider.notifier);
    await notifier.addTarget(target);

    if (!mounted) return;

    // Now open the camera screen with the target ID
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChronographCameraScreen(targetId: targetId),
      ),
    );

    // After recording, close this screen since target is already saved
    if (mounted) {
      ref.invalidate(targetsByRangeSessionIdProvider(widget.rangeSessionId));
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Target and velocities saved successfully'),
        ),
      );
    }
  }

  Future<void> _saveTarget() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final isEditing = widget.target != null;
    final now = DateTime.now();

    // Get shot count from velocities if editing
    int shotCount = 0;
    if (isEditing) {
      final velocities = await ref.read(
        shotVelocitiesByTargetIdProvider(widget.target!.id).future,
      );
      shotCount = velocities.length;
    }

    final target = Target(
      id: isEditing ? widget.target!.id : const Uuid().v4(),
      rangeSessionId: widget.rangeSessionId,
      distance: double.parse(_distanceController.text),
      numberOfShots: shotCount, // Use velocity count if editing, 0 if new
      groupSizeInches: _groupInchesController.text.isEmpty
          ? null
          : double.tryParse(_groupInchesController.text),
      photoPath: _photoPath,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: isEditing ? widget.target!.createdAt : now,
      updatedAt: now,
    );

    final notifier = ref.read(targetNotifierProvider.notifier);

    if (isEditing) {
      await notifier.updateTarget(target);
    } else {
      await notifier.addTarget(target);
    }

    ref.invalidate(targetsByRangeSessionIdProvider(widget.rangeSessionId));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Target updated successfully'
                : 'Target added successfully',
          ),
        ),
      );
    }
  }

  Widget _buildCollapsibleVelocityList(
    BuildContext context,
    WidgetRef ref,
    List<ShotVelocity> velocities,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isVelocityListExpanded = !_isVelocityListExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _isVelocityListExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Individual Shot Velocities (${velocities.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isVelocityListExpanded) ...[
            const Divider(height: 1),
            ...List.generate(velocities.length, (index) {
              final shot = velocities[index];
              return Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
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
                      DateFormat('MMM dd, h:mm:ss a').format(shot.timestamp),
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
                  if (index < velocities.length - 1) const Divider(height: 1),
                ],
              );
            }),
          ],
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
                  .recalcTargetVelocityStats(widget.target!.id);

              // Refresh the UI
              ref.invalidate(
                shotVelocitiesByTargetIdProvider(widget.target!.id),
              );
              ref.invalidate(
                targetsByRangeSessionIdProvider(widget.rangeSessionId),
              );

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
                  .recalcTargetVelocityStats(widget.target!.id);

              ref.invalidate(
                shotVelocitiesByTargetIdProvider(widget.target!.id),
              );
              ref.invalidate(
                targetsByRangeSessionIdProvider(widget.rangeSessionId),
              );

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

  void _confirmDelete() {
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
              await notifier.deleteTarget(widget.target!.id);
              ref.invalidate(
                targetsByRangeSessionIdProvider(widget.rangeSessionId),
              );
              if (context.mounted) {
                Navigator.pop(context); // Return to session
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
