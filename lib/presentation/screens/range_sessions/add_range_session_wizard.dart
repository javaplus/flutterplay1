import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/range_session.dart';
import '../../providers/range_session_provider.dart';
import '../../providers/firearm_provider.dart';
import '../../providers/load_recipe_provider.dart';

/// Wizard for adding or editing a range session
class AddRangeSessionWizard extends ConsumerStatefulWidget {
  final RangeSession? session;

  const AddRangeSessionWizard({super.key, this.session});

  @override
  ConsumerState<AddRangeSessionWizard> createState() =>
      _AddRangeSessionWizardState();
}

class _AddRangeSessionWizardState extends ConsumerState<AddRangeSessionWizard> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _weatherController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedFirearmId;
  String? _selectedLoadRecipeId;

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  void _loadSessionData() {
    if (widget.session != null) {
      final session = widget.session!;
      _selectedDate = session.date;
      _selectedFirearmId = session.firearmId;
      _selectedLoadRecipeId = session.loadRecipeId;
      _weatherController.text = session.weather ?? '';
      _notesController.text = session.notes ?? '';
    }
  }

  @override
  void dispose() {
    _weatherController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.session != null;
    final firearmsAsync = ref.watch(firearmsListProvider);
    final loadRecipesAsync = ref.watch(loadRecipesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Range Session' : 'Add Range Session'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date'),
                subtitle: Text(_formatDate(_selectedDate)),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),

              // Firearm selector
              firearmsAsync.when(
                data: (firearms) {
                  if (firearms.isEmpty) {
                    return Card(
                      color: Colors.orange[50],
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No firearms available. Please add a firearm first.',
                        ),
                      ),
                    );
                  }
                  return DropdownButtonFormField<String>(
                    value: _selectedFirearmId,
                    decoration: const InputDecoration(
                      labelText: 'Firearm *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.gps_fixed),
                    ),
                    items: firearms.map((firearm) {
                      return DropdownMenuItem(
                        value: firearm.id,
                        child: Text('${firearm.name} (${firearm.caliber})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFirearmId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a firearm';
                      }
                      return null;
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Error loading firearms'),
              ),
              const SizedBox(height: 16),

              // Load Recipe selector
              loadRecipesAsync.when(
                data: (loadRecipes) {
                  if (loadRecipes.isEmpty) {
                    return Card(
                      color: Colors.orange[50],
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No load recipes available. Please add a load recipe first.',
                        ),
                      ),
                    );
                  }
                  return DropdownButtonFormField<String>(
                    value: _selectedLoadRecipeId,
                    decoration: const InputDecoration(
                      labelText: 'Load Recipe *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.science),
                    ),
                    items: loadRecipes.map((recipe) {
                      return DropdownMenuItem(
                        value: recipe.id,
                        child: Text(
                          '${recipe.cartridge} - ${recipe.bulletWeight}gr ${recipe.bulletType}',
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedLoadRecipeId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a load recipe';
                      }
                      return null;
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Error loading load recipes'),
              ),
              const SizedBox(height: 16),

              // Weather
              TextFormField(
                controller: _weatherController,
                decoration: const InputDecoration(
                  labelText: 'Weather (Optional)',
                  hintText: 'e.g., 72°F, sunny, 5mph wind',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.wb_sunny),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'General observations...',
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
                  onPressed: _saveSession,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(isEditing ? 'Update Session' : 'Save Session'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _saveSession() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final isEditing = widget.session != null;
    final now = DateTime.now();

    final session = RangeSession(
      id: isEditing ? widget.session!.id : const Uuid().v4(),
      date: _selectedDate,
      firearmId: _selectedFirearmId!,
      loadRecipeId: _selectedLoadRecipeId!,
      weather: _weatherController.text.trim().isEmpty
          ? null
          : _weatherController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: isEditing ? widget.session!.createdAt : now,
      updatedAt: now,
    );

    final notifier = ref.read(rangeSessionNotifierProvider.notifier);

    if (isEditing) {
      await notifier.updateRangeSession(session);
    } else {
      await notifier.addRangeSession(session);
    }

    ref.invalidate(rangeSessionsListProvider);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Range session updated successfully'
                : 'Range session added successfully',
          ),
        ),
      );
    }
  }
}
