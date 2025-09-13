import 'package:flutter/material.dart';
import 'package:scooby_app_new/controllers/pet_form_controller.dart';
import 'package:scooby_app_new/controllers/pet_service.dart';
import 'package:scooby_app_new/models/pet.dart';

class PetFormScreen extends StatefulWidget {
  final Pet? existingPet;
  final String authUserId;

  const PetFormScreen({super.key, this.existingPet, required this.authUserId});

  @override
  State<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends State<PetFormScreen> {
  late PetFormController controller;

  @override
  void initState() {
    super.initState();
    controller = PetFormController(
      existingPet: widget.existingPet,
      petService: PetService(),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _savePet() async {
    final success = await controller.savePet(
      widget.authUserId,
      context,
      existingId: widget.existingPet?.id,
    );

    if (success) {
      if (!mounted) return;
      Navigator.pop(context, true); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingPet != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Pet" : "Add Pet"),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _savePet,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: () async {
                await controller.pickImage();
                setState(() {});
              },
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.deepPurple.shade100,
                backgroundImage: controller.imageProvider,
                child: controller.imageProvider == null
                    ? const Icon(Icons.camera_alt, color: Colors.deepPurple, size: 32)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(controller.nameController, "Pet Name *"),
            _buildDropdown(controller.type, "Type *", ["Dog", "Cat", "Bird", "Other"]),
            _buildTextField(controller.breedController, "Breed *"),
            _buildDropdown(controller.gender, "Gender *", ["Male", "Female"]),
            _buildTextField(controller.ageController, "Age (years) *", keyboardType: TextInputType.number),
            _buildTextField(controller.colorController, "Color"),
            _buildTextField(controller.weightController, "Weight (kg)", keyboardType: TextInputType.number),
            _buildTextField(controller.heightController, "Height (cm)", keyboardType: TextInputType.number),
            _buildTextField(controller.foodController, "Allergies "),
 
            _buildTextField(controller.descriptionController, "Description", maxLines: 3),

            const SizedBox(height: 20),
            const Text("Medical History", style: TextStyle(fontWeight: FontWeight.bold)),
            ..._buildMedicalFields(),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              onPressed: () {
                setState(() => controller.addMedicalRecord());
              },
              icon: const Icon(Icons.add),
              label: const Text("Add Record"),
            ),

            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                    onPressed: _savePet,
                    child: const Text("Save"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildDropdown(
      ValueNotifier<String?> notifier,
      String label,
      List<String> options,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ValueListenableBuilder<String?>(
        valueListenable: notifier,
        builder: (context, value, _) {
          final safeValue = options.contains(value) ? value : null; // guard
          return DropdownButtonFormField<String>(
            initialValue: safeValue, // <- was initialValue
            hint: Text('Select ${label.replaceAll('*', '').trim()}'),
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: options
                .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                .toList(),
            onChanged: (val) => notifier.value = val,
            validator: (val) => val == null && label.contains('*') ? 'Required' : null,
          );
        },
      ),
    );
  }

  List<Widget> _buildMedicalFields() {
    return List.generate(controller.medicalControllers.length, (index) {
      return Row(
        children: [
          Expanded(
            child: _buildTextField(controller.medicalControllers[index], "Record ${index + 1}"),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              setState(() => controller.removeMedicalRecord(index));
            },
          )
        ],
      );
    });
  }
}
