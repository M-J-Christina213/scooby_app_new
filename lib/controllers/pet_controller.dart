import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scooby_app_new/models/pet.dart';

class PetController {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController breedController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController medicalController = TextEditingController();
  final TextEditingController foodController = TextEditingController();
  final TextEditingController moodController = TextEditingController();
  final TextEditingController healthController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final ValueNotifier<String?> type = ValueNotifier(null);
  final ValueNotifier<String?> gender = ValueNotifier(null);

  File? imageFile;

  PetController({Pet? existingPet}) {
    // If editing an existing pet, prefill the controllers with existing data
    if (existingPet != null) {
      nameController.text = existingPet.name;
      ageController.text = existingPet.age.toString();
      breedController.text = existingPet.breed ?? '';
      colorController.text = existingPet.color ?? '';
      weightController.text = existingPet.weight?.toString() ?? '';
      heightController.text = existingPet.height?.toString() ?? '';
      medicalController.text = existingPet.medicalHistory ?? '';
      foodController.text = existingPet.foodPreference ?? '';
      moodController.text = existingPet.mood ?? '';
      healthController.text = existingPet.healthStatus ?? '';
      descriptionController.text = existingPet.description ?? '';
      type.value = existingPet.type;
      gender.value = existingPet.gender;

      // If you have an image URL, you could handle loading it later or leave for UI
      // imageFile remains null unless user picks a new image
    }
  }

  /// Get image provider for CircleAvatar
  ImageProvider? get imageProvider {
    if (imageFile != null) return FileImage(imageFile!);
    // If you want to show existingPet image URL here, add logic accordingly.
    return null;
  }

  /// Pick image from gallery
  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      imageFile = File(picked.path);
    }
  }

  /// Save pet - add your backend save/update logic here
  void savePet(BuildContext context) {
    if (_validateForm(context)) {
      // Save or update pet in backend or local storage

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pet saved successfully!')),
      );

      Navigator.pop(context);
    }
  }

  /// Basic form validation
  bool _validateForm(BuildContext context) {
    if (nameController.text.isEmpty ||
        ageController.text.isEmpty ||
        breedController.text.isEmpty ||
        type.value == null ||
        gender.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return false;
    }
    return true;
  }

  void dispose() {
    nameController.dispose();
    ageController.dispose();
    breedController.dispose();
    colorController.dispose();
    weightController.dispose();
    heightController.dispose();
    medicalController.dispose();
    foodController.dispose();
    moodController.dispose();
    healthController.dispose();
    descriptionController.dispose();
  }
}
