import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/load_recipe.dart';
import '../../providers/load_recipe_provider.dart';

/// Multi-step wizard for adding or editing a load recipe
class AddEditLoadRecipeWizard extends ConsumerStatefulWidget {
  final LoadRecipe? loadRecipe; // null for add, non-null for edit

  const AddEditLoadRecipeWizard({super.key, this.loadRecipe});

  @override
  ConsumerState<AddEditLoadRecipeWizard> createState() =>
      _AddEditLoadRecipeWizardState();
}

class _AddEditLoadRecipeWizardState
    extends ConsumerState<AddEditLoadRecipeWizard> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Form controllers
  final _cartridgeController = TextEditingController();
  final _bulletWeightController = TextEditingController();
  final _bulletTypeController = TextEditingController();
  final _powderTypeController = TextEditingController();
  final _powderChargeController = TextEditingController();
  final _primerTypeController = TextEditingController();
  final _brassTypeController = TextEditingController();
  final _brassPrepController = TextEditingController();
  final _coalLengthController = TextEditingController();
  final _seatingDepthController = TextEditingController();
  final _crimpController = TextEditingController();
  final _notesController = TextEditingController();

  final Set<String> _selectedPressureSigns = {};

  @override
  void initState() {
    super.initState();
    _loadLoadRecipeData();
  }

  void _loadLoadRecipeData() {
    if (widget.loadRecipe != null) {
      final recipe = widget.loadRecipe!;
      _cartridgeController.text = recipe.cartridge;
      _bulletWeightController.text = recipe.bulletWeight.toString();
      _bulletTypeController.text = recipe.bulletType;
      _powderTypeController.text = recipe.powderType;
      _powderChargeController.text = recipe.powderCharge.toString();
      _primerTypeController.text = recipe.primerType;
      _brassTypeController.text = recipe.brassType;
      _brassPrepController.text = recipe.brassPrep;
      _coalLengthController.text = recipe.coalLength.toString();
      _seatingDepthController.text = recipe.seatingDepth.toString();
      _crimpController.text = recipe.crimp;
      _notesController.text = recipe.notes ?? '';
      _selectedPressureSigns.addAll(recipe.pressureSigns);
    }
  }

  @override
  void dispose() {
    _cartridgeController.dispose();
    _bulletWeightController.dispose();
    _bulletTypeController.dispose();
    _powderTypeController.dispose();
    _powderChargeController.dispose();
    _primerTypeController.dispose();
    _brassTypeController.dispose();
    _brassPrepController.dispose();
    _coalLengthController.dispose();
    _seatingDepthController.dispose();
    _crimpController.dispose();
    _notesController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.loadRecipe != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Load Recipe' : 'Add Load Recipe'),
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
                  _buildStep1CartridgeAndBullet(),
                  _buildStep2PowderAndPrimer(),
                  _buildStep3BrassAndDimensions(),
                  _buildStep4PressureAndNotes(),
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

  Widget _buildStep1CartridgeAndBullet() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 1: Cartridge & Bullet',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the cartridge and bullet information',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Cartridge
          TextFormField(
            controller: _cartridgeController,
            decoration: const InputDecoration(
              labelText: 'Cartridge *',
              hintText: 'e.g., .308 Win, 6.5 Creedmoor',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.label),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a cartridge';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Bullet Weight
          TextFormField(
            controller: _bulletWeightController,
            decoration: const InputDecoration(
              labelText: 'Bullet Weight (grains) *',
              hintText: 'e.g., 168',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.scale),
              suffixText: 'gr',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter bullet weight';
              }
              final weight = double.tryParse(value);
              if (weight == null || weight <= 0) {
                return 'Please enter a valid weight';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Bullet Type
          TextFormField(
            controller: _bulletTypeController,
            decoration: const InputDecoration(
              labelText: 'Bullet Type *',
              hintText: 'e.g., HPBT, FMJ, Polymer Tip',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter bullet type';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep2PowderAndPrimer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 2: Powder & Primer',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the powder and primer details',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Powder Type
          TextFormField(
            controller: _powderTypeController,
            decoration: const InputDecoration(
              labelText: 'Powder Type *',
              hintText: 'e.g., H4895, Varget, IMR 4064',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.science),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter powder type';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Powder Charge
          TextFormField(
            controller: _powderChargeController,
            decoration: const InputDecoration(
              labelText: 'Powder Charge (grains) *',
              hintText: 'e.g., 42.5',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.balance),
              suffixText: 'gr',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter powder charge';
              }
              final charge = double.tryParse(value);
              if (charge == null || charge <= 0) {
                return 'Please enter a valid charge';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Primer Type
          TextFormField(
            controller: _primerTypeController,
            decoration: const InputDecoration(
              labelText: 'Primer Type *',
              hintText: 'e.g., CCI 200, Federal 210M',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.fiber_manual_record),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter primer type';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep3BrassAndDimensions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 3: Brass & Dimensions',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter brass details and cartridge dimensions',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Brass Type
          TextFormField(
            controller: _brassTypeController,
            decoration: const InputDecoration(
              labelText: 'Brass Type *',
              hintText: 'e.g., Lapua, Winchester, Federal',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.hardware),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter brass type';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Brass Prep
          TextFormField(
            controller: _brassPrepController,
            decoration: const InputDecoration(
              labelText: 'Brass Prep *',
              hintText: 'e.g., Annealed, Full length sized',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.build),
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter brass prep details';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // COAL (Cartridge Overall Length)
          TextFormField(
            controller: _coalLengthController,
            decoration: const InputDecoration(
              labelText: 'COAL (Cartridge Overall Length) *',
              hintText: 'e.g., 2.800',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.straighten),
              suffixText: 'in',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,4}')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter COAL';
              }
              final length = double.tryParse(value);
              if (length == null || length <= 0) {
                return 'Please enter a valid length';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Seating Depth
          TextFormField(
            controller: _seatingDepthController,
            decoration: const InputDecoration(
              labelText: 'Seating Depth *',
              hintText: 'e.g., 0.020',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.height),
              suffixText: 'in',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,4}')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter seating depth';
              }
              final depth = double.tryParse(value);
              if (depth == null || depth < 0) {
                return 'Please enter a valid depth';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Crimp
          TextFormField(
            controller: _crimpController,
            decoration: const InputDecoration(
              labelText: 'Crimp *',
              hintText: 'e.g., None, Light roll crimp, 0.003"',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.compress),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter crimp info';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep4PressureAndNotes() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 4: Pressure Signs & Notes',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Select any pressure signs and add notes',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Pressure Signs
          Text(
            'Pressure Signs',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
              children: PressureSignTypes.all.map((sign) {
                return CheckboxListTile(
                  title: Text(sign),
                  value: _selectedPressureSigns.contains(sign),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedPressureSigns.add(sign);
                      } else {
                        _selectedPressureSigns.remove(sign);
                      }
                    });
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Notes
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (Optional)',
              hintText: 'e.g., Best accuracy so far, try more...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.note),
              alignLabelWithHint: true,
            ),
            maxLines: 5,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final isLastStep = _currentStep == _totalSteps - 1;
    final isFirstStep = _currentStep == 0;

    return Container(
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
          if (!isFirstStep)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: const Text('Back'),
              ),
            ),
          if (!isFirstStep) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: isLastStep ? _saveLoadRecipe : _nextStep,
              child: Text(isLastStep ? 'Save' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _currentStep++;
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  void _previousStep() {
    setState(() {
      _currentStep--;
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  void _confirmCancel() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('Are you sure you want to discard your changes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Editing'),
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

  Future<void> _saveLoadRecipe() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final isEditing = widget.loadRecipe != null;
    final now = DateTime.now();

    final loadRecipe = LoadRecipe(
      id: isEditing ? widget.loadRecipe!.id : const Uuid().v4(),
      cartridge: _cartridgeController.text.trim(),
      bulletWeight: double.parse(_bulletWeightController.text),
      bulletType: _bulletTypeController.text.trim(),
      powderType: _powderTypeController.text.trim(),
      powderCharge: double.parse(_powderChargeController.text),
      primerType: _primerTypeController.text.trim(),
      brassType: _brassTypeController.text.trim(),
      brassPrep: _brassPrepController.text.trim(),
      coalLength: double.parse(_coalLengthController.text),
      seatingDepth: double.parse(_seatingDepthController.text),
      crimp: _crimpController.text.trim(),
      pressureSigns: _selectedPressureSigns.toList(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: isEditing ? widget.loadRecipe!.createdAt : now,
      updatedAt: now,
    );

    final notifier = ref.read(loadRecipeNotifierProvider.notifier);

    if (isEditing) {
      await notifier.updateLoadRecipe(loadRecipe);
    } else {
      await notifier.addLoadRecipe(loadRecipe);
    }

    // Invalidate the list to refresh
    ref.invalidate(loadRecipesListProvider);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Load recipe updated successfully'
                : 'Load recipe added successfully',
          ),
        ),
      );
    }
  }
}
