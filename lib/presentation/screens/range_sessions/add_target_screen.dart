import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/target.dart';
import '../../providers/range_session_provider.dart';
import '../../providers/shot_velocity_provider.dart';
import 'chronograph_camera_screen.dart';

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

              // Number of shots display (read-only, auto-populated from velocities)
              if (isEditing)
                velocitiesAsync?.when(
                      data: (velocities) => Card(
                        color: Colors.blue[50],
                        child: ListTile(
                          leading: const Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                          ),
                          title: Text(
                            'Recorded Shots: ${velocities.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text(
                            'Number of shots is automatically counted from recorded velocities',
                          ),
                        ),
                      ),
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
                  child: ListTile(
                    leading: const Icon(Icons.photo),
                    title: const Text('Photo selected'),
                    subtitle: Text(_photoPath!.split('/').last),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _photoPath = null;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              OutlinedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.camera_alt),
                label: Text(_photoPath == null ? 'Take Photo' : 'Change Photo'),
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
      });
    }
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
