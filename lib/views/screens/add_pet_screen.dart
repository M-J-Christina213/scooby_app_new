import 'package:flutter/material.dart';
import 'package:scooby_app_new/controllers/pet_controller.dart';
import 'package:scooby_app_new/models/pet.dart';

class PetFormScreen extends StatefulWidget {
  final Pet? pet;
  const PetFormScreen({this.pet, super.key});

  @override
  State<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends State<PetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late PetController _controller;
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    _controller = PetController(existingPet: widget.pet);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.pet != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Pet' : 'Create Pet')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GestureDetector(
              onTap: _controller.pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _controller.imageProvider,
                child: _controller.imageProvider == null
                  ? const Icon(Icons.camera_alt)
                  : null,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField("Name", _controller.nameController),
            _buildTextField("Age", _controller.ageController, isNumber: true),
            _buildTextField("Breed", _controller.breedController),
            _buildDropdown("Type", _controller.type, ["Dog", "Cat"]),
            _buildDropdown("Gender", _controller.gender, ["Male", "Female"]),
            _buildTextField("Color", _controller.colorController),
            _buildTextField("Weight (kg)", _controller.weightController, isNumber: true),
            _buildTextField("Height (cm)", _controller.heightController, isNumber: true),
            _buildTextField("Medical History", _controller.medicalController),
            _buildTextField("Food Preference", _controller.foodController),
            _buildTextField("Mood", _controller.moodController),
            _buildTextField("Health Status", _controller.healthController),
            _buildTextField("Fun Fact / Description", _controller.descriptionController),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _controller.savePet(context),
              child: Text(isEdit ? 'Save Changes' : 'Create Pet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildDropdown(String label, ValueNotifier<String?> selectedValue, List<String> options) {
    return ValueListenableBuilder<String?>(
      valueListenable: selectedValue,
      builder: (_, value, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: DropdownButtonFormField<String>(
          value: value,
          onChanged: (val) => selectedValue.value = val,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        ),
      ),
    );
  }
}
