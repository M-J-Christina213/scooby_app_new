import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:scooby_app_new/controllers/pet_form_controller.dart';
import 'package:scooby_app_new/controllers/pet_service.dart';

class AddPetScreen extends StatefulWidget {
  final String userId;
  const AddPetScreen({required this.userId, super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  late final PetFormController _formController;
  final _formKey = GlobalKey<FormState>();
  final Color _primaryColor = const Color(0xFF842EAC);

  @override
  void initState() {
    super.initState();
    _formController = PetFormController(petService: PetService());
  }

  @override
  void dispose() {
    _formController.dispose();
    super.dispose();
  }

  void _showFlushbar(String message,
      {Color backgroundColor = const Color(0xFF842EAC), IconData icon = Icons.pets}) {
    Flushbar(
      message: message,
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: backgroundColor,
      margin: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(12),
      icon: Icon(icon, color: Colors.white),
    ).show(context);
  }

  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate()) {
      _showFlushbar('Please fix the errors in the form',
          backgroundColor: Colors.redAccent, icon: Icons.error);
      return;
    }

    final success = await _formController.savePet(widget.userId, context);
    if (success) {
      _showFlushbar('Pet added successfully!');
      if (mounted) Navigator.of(context).pop(true);
    } else {
      _showFlushbar('Failed to add pet', backgroundColor: Colors.redAccent, icon: Icons.error);
    }
  }

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: _primaryColor.withAlpha((0.9 * 255).round()),
            )),
      );

  @override
  Widget build(BuildContext context) {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _primaryColor.withAlpha((0.6 * 255).round()), width: 1.5),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Pet'),
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
                _buildSectionTitle('Basic Information'),
                TextFormField(
                  controller: _formController.nameController,
                  decoration: InputDecoration(
                    labelText: 'Name *',
                    hintText: 'Enter pet name',
                    border: inputBorder,
                    focusedBorder: inputBorder.copyWith(
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<String?>(
                  valueListenable: _formController.type,
                  builder: (context, value, _) {
                    return DropdownButtonFormField<String>(
                      value: value,
                      decoration: InputDecoration(
                        labelText: 'Type *',
                        border: inputBorder,
                        focusedBorder: inputBorder.copyWith(
                          borderSide: BorderSide(color: _primaryColor, width: 2),
                        ),
                      ),
                      items: ['Dog', 'Cat']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) => _formController.type.value = val,
                      validator: (v) => (v == null || v.isEmpty) ? 'Please select type' : null,
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _formController.breedController,
                  decoration: InputDecoration(
                    labelText: 'Breed *',
                    hintText: 'Enter breed',
                    border: inputBorder,
                    focusedBorder: inputBorder.copyWith(
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Breed is required' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _formController.ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Age *',
                    hintText: 'Enter age in years',
                    border: inputBorder,
                    focusedBorder: inputBorder.copyWith(
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Age is required';
                    final age = int.tryParse(v.trim());
                    if (age == null || age < 0) return 'Enter valid age';
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<String?>(
                  valueListenable: _formController.gender,
                  builder: (context, value, _) {
                    return DropdownButtonFormField<String>(
                      value: value,
                      decoration: InputDecoration(
                        labelText: 'Gender *',
                        
                        border: inputBorder,
                        focusedBorder: inputBorder.copyWith(
                          borderSide: BorderSide(color: _primaryColor, width: 2),
                        ),
                      ),
                      items: ['Male', 'Female']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) => _formController.gender.value = val,
                      validator: (v) => (v == null || v.isEmpty) ? 'Please select gender' : null,
                    );
                  },
                ),
                const SizedBox(height: 30),
                _buildSectionTitle('Additional Details (Optional)'),
                TextFormField(
                  controller: _formController.colorController,
                  decoration: InputDecoration(
                    labelText: 'Color',
                    hintText: 'Enter color',
                    border: inputBorder,
                    focusedBorder: inputBorder.copyWith(
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _formController.weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Weight (kg)',
                    hintText: 'Enter weight',
                    border: inputBorder,
                    focusedBorder: inputBorder.copyWith(
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _formController.heightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Height (cm)',
                    hintText: 'Enter height',
                    border: inputBorder,
                    focusedBorder: inputBorder.copyWith(
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _formController.medicalController,
                  decoration: InputDecoration(
                    labelText: 'Medical History',
                    hintText: 'Enter medical history',
                    border: inputBorder,
                    focusedBorder: inputBorder.copyWith(
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                  ),
                  maxLines: 2,
                  textInputAction: TextInputAction.newline,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _formController.foodController,
                  decoration: InputDecoration(
                    labelText: 'Food Preference',
                    hintText: 'Enter food preferences',
                    border: inputBorder,
                    focusedBorder: inputBorder.copyWith(
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                  ),
                  maxLines: 2,
                  textInputAction: TextInputAction.newline,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _formController.moodController,
                  decoration: InputDecoration(
                    labelText: 'Mood',
                    hintText: 'Describe mood',
                    border: inputBorder,
                    focusedBorder: inputBorder.copyWith(
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _formController.healthController,
                  decoration: InputDecoration(
                    labelText: 'Health Status',
                    hintText: 'Describe health status',
                    border: inputBorder,
                    focusedBorder: inputBorder.copyWith(
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _formController.descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Additional details',
                    border: inputBorder,
                    focusedBorder: inputBorder.copyWith(
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                  ),
                  maxLines: 3,
                  textInputAction: TextInputAction.newline,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _formController.isSaving ? null : _savePet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                      shadowColor: _primaryColor.withAlpha((0.5 * 255).round()),
                    ),
                    child: _formController.isSaving
                        ? const SizedBox(
                            height: 26,
                            width: 26,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                          )
                        : const Text(
                            'Add Pet',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
