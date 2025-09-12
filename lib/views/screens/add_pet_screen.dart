import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:scooby_app_new/controllers/pet_form_controller.dart';
import 'package:scooby_app_new/controllers/pet_service.dart';
import 'package:scooby_app_new/models/pet.dart';

class AddPetScreen extends StatefulWidget {
  final String userId;
  final Pet? existingPet;

  const AddPetScreen({required this.userId, this.existingPet, super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  late final PetFormController _formController;
  final _formKey = GlobalKey<FormState>();
  final Color _primaryColor = const Color(0xFF842EAC);
  bool _isEditing = false;

  final TextEditingController _startTimeCtrl = TextEditingController();
  final TextEditingController _endTimeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isEditing = widget.existingPet != null;
    _formController = PetFormController(
      existingPet: widget.existingPet,
      petService: PetService(),
    );

    // Pre-fill display if editing existing pet
    _startTimeCtrl.text = _displayFromDb(_formController.startWalkingTime) ?? '';
    _endTimeCtrl.text = _displayFromDb(_formController.endWalkingTime) ?? '';
  }

  @override
  void dispose() {
    _formController.dispose();
    _startTimeCtrl.dispose();
    _endTimeCtrl.dispose();
    super.dispose();
  }

  String? _displayFromDb(String? hhmmss) {
    if (hhmmss == null || hhmmss.isEmpty) return null;
    final parts = hhmmss.split(':');
    if (parts.length < 2) return hhmmss;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final tod = TimeOfDay(hour: h, minute: m);
    return tod.format(context);
  }

  int _minutesFromDb(String hhmmss) {
    final p = hhmmss.split(':');
    final h = int.parse(p[0]);
    final m = int.parse(p[1]);
    return h * 60 + m;
  }

  Future<void> _showFlushbar(String message,
      {Color backgroundColor = const Color(0xFF842EAC), IconData icon = Icons.pets}) {
    return Flushbar(
      message: message,
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: backgroundColor,
      margin: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(12),
      icon: Icon(icon, color: Colors.white),
    ).show(context);
  }

  Future<void> _pickStartTime() async {
    final init = TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: init);
    if (picked != null) {
      _formController.setStartTime(picked);
      _startTimeCtrl.text = picked.format(context);
      setState(() {});
    }
  }

  Future<void> _pickEndTime() async {
    final init = TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: init);
    if (picked != null) {
      _formController.setEndTime(picked);
      _endTimeCtrl.text = picked.format(context);
      setState(() {});
    }
  }

  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate()) {
      await _showFlushbar('Please fix the errors in the form',
          backgroundColor: Colors.redAccent, icon: Icons.error);
      return;
    }

    final start = _formController.startWalkingTime;
    final end = _formController.endWalkingTime;

    if (start == null || start.isEmpty || end == null || end.isEmpty) {
      await _showFlushbar('Please select both start and end walking times',
          backgroundColor: Colors.redAccent, icon: Icons.error);
      return;
    }

    final sm = _minutesFromDb(start);
    final em = _minutesFromDb(end);

    if (em - sm < 10) {
      await _showFlushbar(
        'End time must be at least 10 minutes after start time',
        backgroundColor: Colors.redAccent,
        icon: Icons.error,
      );
      return;
    }

    final existingId = _isEditing ? widget.existingPet!.id : null;

    final success =
        await _formController.savePet(widget.userId, context, existingId: existingId);

    if (success) {
      await _showFlushbar(_isEditing ? 'Pet updated successfully!' : 'Pet added successfully!');
      if (mounted) Navigator.of(context).pop(true);
    } else {
      await _showFlushbar(_isEditing ? 'Failed to update pet' : 'Failed to add pet',
          backgroundColor: Colors.redAccent, icon: Icons.error);
    }
  }

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: _primaryColor.withAlpha((0.9 * 255).round()),
          ),
        ),
      );

  Widget _buildMedicalHistoryFields() {
    return Column(
      children: List.generate(_formController.medicalControllers.length, (index) {
        final controller = _formController.medicalControllers[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'Medical Record ${index + 1}',
                    hintText: 'Enter medical record',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 2,
                  textInputAction: TextInputAction.newline,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    onPressed: () {
                      setState(() {
                        _formController.addMedicalRecord();
                      });
                    },
                  ),
                  if (_formController.medicalControllers.length > 1)
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _formController.removeMedicalRecord(index);
                        });
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide:
          BorderSide(color: _primaryColor.withAlpha((0.6 * 255).round()), width: 1.5),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Pet' : 'Add New Pet'),
        backgroundColor: _primaryColor,
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Avatar + Camera
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 65,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _formController.imageProvider,
                      child: _formController.imageProvider == null
                          ? Icon(Icons.pets,
                              size: 60, color: _primaryColor.withAlpha((0.4 * 255).round()))
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 4,
                      child: GestureDetector(
                        onTap: () async {
                          await _formController.pickImage();
                          setState(() {});
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.camera_alt, color: Colors.white),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 25),

                // --- Basic Info ---
                _buildSectionTitle('Basic Information'),
                TextFormField(
                  controller: _formController.nameController,
                  decoration: InputDecoration(
                    labelText: 'Name *',
                    hintText: 'Enter pet name',
                    border: inputBorder,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<String?>(
                  valueListenable: _formController.type,
                  builder: (context, value, _) {
                    final items = const ['Dog', 'Cat'];
                    final safeValue = items.contains(value) ? value : null;
                    return DropdownButtonFormField<String>(
                      value: safeValue,
                      hint: const Text('Select type'),
                      decoration: InputDecoration(labelText: 'Type *', border: inputBorder),
                      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) => _formController.type.value = val,
                      validator: (v) => (v == null || v.isEmpty) ? 'Please select type' : null,
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _formController.breedController,
                  decoration: InputDecoration(labelText: 'Breed *', border: inputBorder),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Breed is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _formController.ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Age *', border: inputBorder),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Age is required';
                    final age = int.tryParse(v.trim());
                    if (age == null || age < 0) return 'Enter valid age';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<String?>(
                  valueListenable: _formController.gender,
                  builder: (context, value, _) {
                    final items = const ['Male', 'Female'];
                    final safeValue = items.contains(value) ? value : null;
                    return DropdownButtonFormField<String>(
                      value: safeValue,
                      hint: const Text('Select gender'),
                      decoration: InputDecoration(labelText: 'Gender *', border: inputBorder),
                      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) => _formController.gender.value = val,
                      validator: (v) => (v == null || v.isEmpty) ? 'Please select gender' : null,
                    );
                  },
                ),

                const SizedBox(height: 30),

                // --- Additional Details ---
                _buildSectionTitle('Additional Details (Optional)'),
                TextFormField(
                  controller: _formController.colorController,
                  decoration: InputDecoration(labelText: 'Color', border: inputBorder),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _formController.weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: 'Weight (kg)', border: inputBorder),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _formController.heightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: 'Height (cm)', border: inputBorder),
                ),
                const SizedBox(height: 16),

                // --- Walking Time ---
                _buildSectionTitle('Walking Time'),
                TextFormField(
                  controller: _startTimeCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Start time *',
                    hintText: 'Select start time',
                    border: inputBorder,
                    suffixIcon: const Icon(Icons.schedule),
                  ),
                  onTap: _pickStartTime,
                  validator: (v) => (v == null || v.isEmpty) ? 'Please select start time' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _endTimeCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'End time *',
                    hintText: 'Select end time',
                    border: inputBorder,
                    suffixIcon: const Icon(Icons.schedule),
                  ),
                  onTap: _pickEndTime,
                  validator: (v) => (v == null || v.isEmpty) ? 'Please select end time' : null,
                ),
                const SizedBox(height: 16),

                // --- Medical / Allergies ---
                _buildSectionTitle('Medical / Allergies'),
                _buildMedicalHistoryFields(),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _formController.foodController,
                  decoration: InputDecoration(labelText: 'Allergies', border: inputBorder),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _formController.descriptionController,
                  decoration: InputDecoration(labelText: 'Description', border: inputBorder),
                  maxLines: 3,
                  textInputAction: TextInputAction.newline,
                ),
                const SizedBox(height: 40),

                // --- Buttons ---
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _formController.isSaving ? null : _savePet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _formController.isSaving
                            ? const SizedBox(
                                height: 26,
                                width: 26,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 3),
                              )
                            : Text(_isEditing ? 'Save Changes' : 'Add Pet'),
                      ),
                    ),
                    if (_isEditing) const SizedBox(width: 16),
                    if (_isEditing)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _formController.isSaving
                              ? null
                              : () => Navigator.of(context).pop(false),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                          child: const Text('Cancel'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
