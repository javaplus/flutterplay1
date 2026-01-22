import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/calibers.dart';
import '../../../domain/entities/firearm.dart';
import '../../providers/firearm_provider.dart';

/// Multi-step wizard for adding or editing a firearm
class AddEditFirearmWizard extends ConsumerStatefulWidget {
  final Firearm? firearm; // null for add, non-null for edit

  const AddEditFirearmWizard({super.key, this.firearm});

  @override
  ConsumerState<AddEditFirearmWizard> createState() =>
      _AddEditFirearmWizardState();
}

class _AddEditFirearmWizardState extends ConsumerState<AddEditFirearmWizard> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 3;

  // Form controllers
  final _nameController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _caliberController = TextEditingController();
  final _barrelLengthController = TextEditingController();
  final _barrelTwistRateController = TextEditingController();
  final _roundCountController = TextEditingController();
  final _opticInfoController = TextEditingController();
  final _notesController = TextEditingController();

  String? _photoPath;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadFirearmData();
  }

  void _loadFirearmData() {
    if (widget.firearm != null) {
      final firearm = widget.firearm!;
      _nameController.text = firearm.name;
      _makeController.text = firearm.make;
      _modelController.text = firearm.model;
      _caliberController.text = firearm.caliber;
      _barrelLengthController.text = firearm.barrelLength.toString();
      _barrelTwistRateController.text = firearm.barrelTwistRate;
      _roundCountController.text = firearm.roundCount.toString();
      _opticInfoController.text = firearm.opticInfo ?? '';
      _notesController.text = firearm.notes ?? '';
      _photoPath = firearm.photoPath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _caliberController.dispose();
    _barrelLengthController.dispose();
    _barrelTwistRateController.dispose();
    _roundCountController.dispose();
    _opticInfoController.dispose();
    _notesController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.firearm != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Firearm' : 'Add Firearm'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _confirmCancel,
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),

          // Form pages
          Expanded(
            child: Form(
              key: _formKey,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1BasicInfo(),
                  _buildStep2BarrelSpecs(),
                  _buildStep3AdditionalInfo(),
                ],
              ),
            ),
          ),

          // Navigation buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isComplete = index < _currentStep;
          final isCurrent = index == _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isComplete || isCurrent
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < _totalSteps - 1) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1BasicInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 1: Basic Information',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the basic details of your firearm',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Photo picker
          _buildPhotoPicker(),
          const SizedBox(height: 24),

          // Name (Nickname)
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name / Nickname *',
              hintText: 'e.g., "My AR-15" or "Hunting Rifle"',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.badge),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Make
          TextFormField(
            controller: _makeController,
            decoration: const InputDecoration(
              labelText: 'Make *',
              hintText: 'e.g., "Smith & Wesson", "Ruger"',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.business),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the make';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Model
          TextFormField(
            controller: _modelController,
            decoration: const InputDecoration(
              labelText: 'Model *',
              hintText: 'e.g., "M&P15", "10/22"',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the model';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Caliber (Dropdown)
          DropdownButtonFormField<String>(
            initialValue: _caliberController.text.isNotEmpty
                ? _caliberController.text
                : null,
            items: KnownCalibers.all
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (value) {
              setState(() {
                _caliberController.text = value ?? '';
              });
            },
            decoration: const InputDecoration(
              labelText: 'Caliber / Chambering *',
              hintText: 'Select a caliber',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.adjust),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a caliber';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep2BarrelSpecs() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 2: Barrel Specifications',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Barrel details affect load performance',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Barrel Length
          TextFormField(
            controller: _barrelLengthController,
            decoration: const InputDecoration(
              labelText: 'Barrel Length (inches) *',
              hintText: 'e.g., "16", "20", "24"',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.straighten),
              suffixText: 'in',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the barrel length';
              }
              final parsed = double.tryParse(value);
              if (parsed == null || parsed <= 0) {
                return 'Please enter a valid length';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Barrel Twist Rate
          TextFormField(
            controller: _barrelTwistRateController,
            decoration: const InputDecoration(
              labelText: 'Barrel Twist Rate *',
              hintText: 'e.g., "1:10", "1:7", "1:12"',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.rotate_right),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the twist rate';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Round Count
          TextFormField(
            controller: _roundCountController,
            decoration: const InputDecoration(
              labelText: 'Round Count',
              hintText: 'Approximate number of rounds fired',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.numbers),
              helperText: 'Optional - useful for tracking barrel wear',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ],
      ),
    );
  }

  Widget _buildStep3AdditionalInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 3: Additional Information',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Optional details for reference',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Optic Info
          TextFormField(
            controller: _opticInfoController,
            decoration: const InputDecoration(
              labelText: 'Optic Information',
              hintText: 'e.g., "Vortex 4-16x44, zeroed at 100 yards"',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.center_focus_strong),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // Notes
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Any additional notes about this firearm',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.note),
            ),
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photo',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: _photoPath != null && _photoPath!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(_photoPath!), fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to add photo',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
          ),
        ),
        if (_photoPath != null && _photoPath!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _photoPath = null;
                });
              },
              icon: const Icon(Icons.delete),
              label: const Text('Remove photo'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  child: const Text('Back'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _currentStep < _totalSteps - 1
                    ? _nextStep
                    : _saveFirearm,
                child: Text(_currentStep < _totalSteps - 1 ? 'Next' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _photoPath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Validate step 1
      if (!_formKey.currentState!.validate()) {
        return;
      }
    }

    if (_currentStep == 1) {
      // Validate step 2
      if (!_formKey.currentState!.validate()) {
        return;
      }
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveFirearm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final isEditing = widget.firearm != null;
    final now = DateTime.now();

    final firearm = Firearm(
      id: isEditing ? widget.firearm!.id : const Uuid().v4(),
      name: _nameController.text.trim(),
      make: _makeController.text.trim(),
      model: _modelController.text.trim(),
      caliber: _caliberController.text.trim(),
      barrelLength: double.parse(_barrelLengthController.text),
      barrelTwistRate: _barrelTwistRateController.text.trim(),
      roundCount: int.tryParse(_roundCountController.text) ?? 0,
      opticInfo: _opticInfoController.text.trim().isEmpty
          ? null
          : _opticInfoController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      photoPath: _photoPath,
      createdAt: isEditing ? widget.firearm!.createdAt : now,
      updatedAt: now,
    );

    final notifier = ref.read(firearmNotifierProvider.notifier);

    if (isEditing) {
      await notifier.updateFirearm(firearm);
    } else {
      await notifier.addFirearm(firearm);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Firearm updated' : 'Firearm added'),
        ),
      );
      Navigator.pop(context);
    }
  }

  void _confirmCancel() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Are you sure you want to discard your changes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue editing'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close wizard
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }
}
