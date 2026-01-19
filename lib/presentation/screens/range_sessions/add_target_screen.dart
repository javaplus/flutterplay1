import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/target.dart';
import '../../providers/range_session_provider.dart';

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
  final _shotsController = TextEditingController();
  final _groupInchesController = TextEditingController();
  final _groupCmController = TextEditingController();
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
      _shotsController.text = target.numberOfShots.toString();
      _groupInchesController.text = target.groupSizeInches?.toString() ?? '';
      _groupCmController.text = target.groupSizeCm?.toString() ?? '';
      _notesController.text = target.notes ?? '';
      _photoPath = target.photoPath;
    }
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _shotsController.dispose();
    _groupInchesController.dispose();
    _groupCmController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.target != null;

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

              // Number of shots
              TextFormField(
                controller: _shotsController,
                decoration: const InputDecoration(
                  labelText: 'Number of Shots *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.center_focus_strong),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter number of shots';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              Text(
                'Group Size (at least one)',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Group size in inches
              TextFormField(
                controller: _groupInchesController,
                decoration: const InputDecoration(
                  labelText: 'Group Size (inches)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.straighten),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 16),

              // Group size in cm
              TextFormField(
                controller: _groupCmController,
                decoration: const InputDecoration(
                  labelText: 'Group Size (cm)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.straighten),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
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

  Future<void> _saveTarget() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Ensure at least one group size is provided
    if (_groupInchesController.text.isEmpty &&
        _groupCmController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter group size in inches or centimeters'),
        ),
      );
      return;
    }

    final isEditing = widget.target != null;
    final now = DateTime.now();

    final target = Target(
      id: isEditing ? widget.target!.id : const Uuid().v4(),
      rangeSessionId: widget.rangeSessionId,
      distance: double.parse(_distanceController.text),
      numberOfShots: int.parse(_shotsController.text),
      groupSizeInches: _groupInchesController.text.isEmpty
          ? null
          : double.tryParse(_groupInchesController.text),
      groupSizeCm: _groupCmController.text.isEmpty
          ? null
          : double.tryParse(_groupCmController.text),
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
