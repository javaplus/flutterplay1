import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/target.dart';
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
      appBar: AppBar(title: Text(isEditing ? 'Edit Target' : 'Add Target')),
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
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveTarget,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(isEditing ? 'Update Target' : 'Save Target'),
                  ),
                ),
              ),
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
      setState(() {
        _photoPath = photo.path;
        _groupSizeFromAnalysis = false;
      });
    }
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
}
