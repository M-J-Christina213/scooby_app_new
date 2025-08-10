

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:scooby_app_new/controllers/pet_form_controller.dart';
import 'package:scooby_app_new/controllers/pet_service.dart';
import 'package:scooby_app_new/models/pet.dart';


class PetDetailScreen extends StatefulWidget {
  final Pet pet;
  final String userId;

  const PetDetailScreen({required this.pet, required this.userId, super.key});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  late PetFormController _formController;
  final Color _primaryColor = const Color(0xFF842EAC);
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _formController = PetFormController(existingPet: widget.pet, petService: PetService());
  }

  @override
  void dispose() {
    _formController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }


Future<void> _saveChanges() async {
  if (!_formController.validate(context)) return;

  setState(() {
    _isSaving = true;
  });

  final success = await _formController.savePet(widget.userId, context, existingId: widget.pet.id);

  setState(() {
    _isSaving = false;
  });

  if (success) {
    // Await the flushbar so pop happens after flushbar finishes
    await Flushbar(
      message: 'Pet updated successfully!',
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: const Color(0xFF842EAC),
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(12),
      icon: const Icon(Icons.pets, color: Colors.white),
    ).show(context);

    if (mounted) {
      setState(() {
        _isEditing = false;
      });
      Navigator.of(context).pop(true); // Indicate to refresh list
    }
  } else {
    await Flushbar(
      message: 'Failed to update pet',
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: Colors.redAccent,
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(12),
      icon: const Icon(Icons.error, color: Colors.white),
    ).show(context);
  }
}


  void _cancelEdit() {
    setState(() {
      _isEditing = false;
    });
    // Reset the form fields back to original pet data
    _formController.dispose();
    _formController = PetFormController(existingPet: widget.pet, petService: PetService());
  }

  Widget _buildTextField(TextEditingController controller,
      {String? label, bool enabled = true, TextInputType? keyboardType, int? maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildDropdown(ValueNotifier<String?> notifier, List<String> options,
      {String? label, bool enabled = true}) {
    return ValueListenableBuilder<String?>(
      valueListenable: notifier,
      builder: (context, value, _) {
        return DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: enabled ? (val) => notifier.value = val : null,
          disabledHint: value != null ? Text(value) : null,
          validator: enabled
              ? (v) => (v == null || v.isEmpty) ? 'Please select $label' : null
              : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Pet' : 'Pet Details'),
        backgroundColor: _primaryColor,
        centerTitle: true,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _toggleEdit,
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: _cancelEdit,
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveChanges,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: GlobalKey<FormState>(), // New form key for this screen
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _isEditing
                      ? () async {
                          await _formController.pickImage();
                          setState(() {});
                        }
                      : null,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _formController.imageProvider ??
                        (widget.pet.imageUrl != null
                            ? NetworkImage(widget.pet.imageUrl!)
                            : null) as ImageProvider<Object>?,
                    child: (_formController.imageProvider == null &&
                            widget.pet.imageUrl == null)
                        ? Icon(Icons.pets, size: 60, color: _primaryColor)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _buildTextField(
                _formController.nameController,
                label: 'Name *',
                enabled: _isEditing,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter name' : null,
              ),
              const SizedBox(height: 16),

              _buildDropdown(
                _formController.type,
                ['Dog', 'Cat', 'Bird', 'Other'],
                label: 'Type *',
                enabled: _isEditing,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                _formController.breedController,
                label: 'Breed *',
                enabled: _isEditing,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter breed' : null,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                _formController.ageController,
                label: 'Age *',
                enabled: _isEditing,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter age';
                  final age = int.tryParse(v.trim());
                  if (age == null || age < 0) return 'Enter valid age';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildDropdown(
                _formController.gender,
                ['Male', 'Female', 'Unknown'],
                label: 'Gender *',
                enabled: _isEditing,
              ),
              const SizedBox(height: 16),

              _buildTextField(_formController.colorController, label: 'Color', enabled: _isEditing),
              const SizedBox(height: 16),

              _buildTextField(
                _formController.weightController,
                label: 'Weight (kg)',
                enabled: _isEditing,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                _formController.heightController,
                label: 'Height (cm)',
                enabled: _isEditing,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                _formController.medicalController,
                label: 'Medical History',
                enabled: _isEditing,
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                _formController.foodController,
                label: 'Food Preference',
                enabled: _isEditing,
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              _buildTextField(_formController.moodController, label: 'Mood', enabled: _isEditing),
              const SizedBox(height: 16),

              _buildTextField(_formController.healthController, label: 'Health Status', enabled: _isEditing),
              const SizedBox(height: 16),

              _buildTextField(
                _formController.descriptionController,
                label: 'Description',
                enabled: _isEditing,
                maxLines: 3,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
