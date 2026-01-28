import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
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
    if (kDebugMode)
      print('🔵 BUILD: AddTargetScreen building, mounted=$mounted');
    final isEditing = widget.target != null;

    // Watch shot velocities if editing to show count
    if (kDebugMode && isEditing)
      print('🔵 BUILD: About to watch shotVelocitiesByTargetIdProvider');
    final velocitiesAsync = isEditing
        ? ref.watch(shotVelocitiesByTargetIdProvider(widget.target!.id))
        : null;
    if (kDebugMode && isEditing) print('🔵 BUILD: Finished watching provider');

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
                    return _buildCollapsibleVelocityList(context, velocities);
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
                          onPressed: () => _showEditShotDialog(context, shot),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          tooltip: 'Delete shot',
                          onPressed: () => _confirmDeleteShot(context, shot),
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

  void _showEditShotDialog(BuildContext context, ShotVelocity shot) {
    final velocityController = TextEditingController(
      text: shot.velocity.toStringAsFixed(0),
    );
    // Track if we're saving to avoid dispose conflicts
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.speed, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Edit Shot Velocity',
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Original: ${shot.velocity.toStringAsFixed(0)} fps',
              style: Theme.of(
                sheetContext,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: velocityController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Velocity',
                suffixText: 'fps',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      // Extract the value BEFORE closing the sheet
                      final newVelocityText = velocityController.text;
                      isSaving = true;
                      Navigator.pop(sheetContext);
                      // Now perform the save with the extracted value
                      _performVelocityUpdate(shot, newVelocityText);
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      // Only dispose if we weren't saving - the save path handles its own cleanup
      if (!isSaving) {
        velocityController.dispose();
      } else {
        // Dispose after a delay to ensure the sheet animation completes
        Future.delayed(const Duration(milliseconds: 300), () {
          velocityController.dispose();
        });
      }
    });
  }

  Future<void> _performVelocityUpdate(
    ShotVelocity shot,
    String velocityText,
  ) async {
    if (kDebugMode) print('🟡 1. _performVelocityUpdate START');
    final newVelocity = double.tryParse(velocityText);

    if (newVelocity == null || newVelocity <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid velocity')),
        );
      }
      return;
    }

    if (!mounted) {
      if (kDebugMode) print('🔴 1a. Widget not mounted, aborting');
      return;
    }

    // Update the shot velocity
    if (kDebugMode) print('🟡 2. Creating updated shot');
    final updatedShot = shot.copyWith(
      velocity: newVelocity,
      updatedAt: DateTime.now(),
    );

    if (kDebugMode) print('🟡 3. Calling updateShotVelocity');
    final shotNotifier = ref.read(shotVelocityNotifierProvider.notifier);
    await shotNotifier.updateShotVelocity(updatedShot);
    if (kDebugMode)
      print('🟡 4. updateShotVelocity complete, mounted=$mounted');

    if (!mounted) {
      if (kDebugMode) print('🔴 4a. Widget not mounted after update, aborting');
      return;
    }

    // Recalculate target statistics
    if (kDebugMode) print('🟡 5. Calling recalcTargetVelocityStats');
    await ref
        .read(targetNotifierProvider.notifier)
        .recalcTargetVelocityStats(widget.target!.id);
    if (kDebugMode)
      print('🟡 6. recalcTargetVelocityStats complete, mounted=$mounted');

    if (!mounted) {
      if (kDebugMode) print('🔴 6a. Widget not mounted after recalc, aborting');
      return;
    }

    // Capture IDs before async work to avoid accessing widget during disposal
    final targetId = widget.target!.id;
    final rangeSessionId = widget.rangeSessionId;
    if (kDebugMode)
      print(
        '🟡 7. Captured IDs: targetId=$targetId, rangeSessionId=$rangeSessionId',
      );

    // Use Future.microtask instead of addPostFrameCallback
    // This ensures we're outside the current build/dispose cycle
    if (kDebugMode) print('🟡 8. Scheduling Future.microtask');
    Future.microtask(() {
      if (kDebugMode)
        print('🟡 9. Future.microtask executing, mounted=$mounted');
      if (!mounted) {
        if (kDebugMode)
          print('🔴 9a. Widget not mounted in microtask, aborting');
        return;
      }

      // Invalidate providers - this will trigger rebuilds
      if (kDebugMode)
        print('🟡 10. About to invalidate shotVelocitiesByTargetIdProvider');
      ref.invalidate(shotVelocitiesByTargetIdProvider(targetId));
      if (kDebugMode)
        print('🟡 11. About to invalidate targetsByRangeSessionIdProvider');
      ref.invalidate(targetsByRangeSessionIdProvider(rangeSessionId));
      if (kDebugMode) print('🟡 12. Providers invalidated, mounted=$mounted');

      if (mounted) {
        if (kDebugMode) print('🟡 13. Showing snackbar');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Shot velocity updated')));
        if (kDebugMode) print('🟡 14. _performVelocityUpdate COMPLETE');
      }
    });
  }

  void _confirmDeleteShot(BuildContext context, ShotVelocity shot) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Shot'),
        content: const Text(
          'Remove this shot velocity from the target? This will update velocity statistics.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _deleteShot(dialogContext, shot),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteShot(
    BuildContext dialogContext,
    ShotVelocity shot,
  ) async {
    // Close dialog first before any async operations
    Navigator.pop(dialogContext);

    if (!mounted) return;

    final shotNotifier = ref.read(shotVelocityNotifierProvider.notifier);
    await shotNotifier.deleteShotVelocity(shot.id);

    if (!mounted) return;

    await ref
        .read(targetNotifierProvider.notifier)
        .recalcTargetVelocityStats(widget.target!.id);

    if (!mounted) return;

    // Capture IDs before async work to avoid accessing widget during disposal
    final targetId = widget.target!.id;
    final rangeSessionId = widget.rangeSessionId;

    // Use Future.microtask instead of addPostFrameCallback
    // This ensures we're outside the current build/dispose cycle
    Future.microtask(() {
      if (!mounted) return;

      // Invalidate providers - this will trigger rebuilds
      ref.invalidate(shotVelocitiesByTargetIdProvider(targetId));
      ref.invalidate(targetsByRangeSessionIdProvider(rangeSessionId));

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Shot removed')));
      }
    });
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
