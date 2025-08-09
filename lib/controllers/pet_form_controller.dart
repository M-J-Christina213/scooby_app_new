// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'pet_service.dart';
import '../models/pet.dart';

class PetFormController {
  final PetService petService;

  // Controllers for all input fields
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

  // Using ValueNotifier for dropdown-like fields
  final ValueNotifier<String?> type = ValueNotifier(null);
  final ValueNotifier<String?> gender = ValueNotifier(null);

  File? imageFile;
  bool _isSaving = false;
  bool get isSaving => _isSaving;

  PetFormController({Pet? existingPet, required this.petService}) {
    // Prefill form if editing an existing pet
    if (existingPet != null) {
      nameController.text = existingPet.name;
      ageController.text = existingPet.age?.toString() ?? '';
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
      // Note: imageFile stays null unless user picks new image
    }
  }

  /// Returns ImageProvider for CircleAvatar
  ImageProvider? get imageProvider {
    if (imageFile != null) return FileImage(imageFile!);
    // Could load existingPet imageUrl here if needed
    return null;
  }

  /// Pick image from gallery
  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      imageFile = File(picked.path);
    }
  }

  /// Validate all required fields before saving
  bool validate(BuildContext context) {
    if (nameController.text.trim().isEmpty ||
        type.value == null ||
        breedController.text.trim().isEmpty ||
        gender.value == null ||
        ageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return false;
    }
    // You can add more validation rules here (e.g. numeric fields)
    return true;
  }

  /// Save pet to backend (add or update)
  Future<bool> savePet(String userId, BuildContext context, {String? existingId}) async {
    if (!validate(context)) return false;

    _isSaving = true;

    try {
      String? imageUrl;

      // Upload new image if picked
      if (imageFile != null) {
        final fileName = '${const Uuid().v4()}.jpg';
        imageUrl = await petService.uploadPetImage(userId, imageFile!.path, fileName);
      }

      final pet = Pet(
        id: existingId ?? const Uuid().v4(),
        userId: userId,
        name: nameController.text.trim(),
        type: type.value,
        breed: breedController.text.trim(),
        age: int.tryParse(ageController.text.trim()),
        gender: gender.value,
        color: colorController.text.trim().isEmpty ? null : colorController.text.trim(),
        weight: double.tryParse(weightController.text.trim()),
        height: double.tryParse(heightController.text.trim()),
        medicalHistory: medicalController.text.trim().isEmpty ? null : medicalController.text.trim(),
        foodPreference: foodController.text.trim().isEmpty ? null : foodController.text.trim(),
        mood: moodController.text.trim().isEmpty ? null : moodController.text.trim(),
        healthStatus: healthController.text.trim().isEmpty ? null : healthController.text.trim(),
        description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      // If updating existing pet, you might want to implement update logic, here we only add
      await petService.addPet(pet);

      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save pet: $e')));
      return false;
    } finally {
      _isSaving = false;
    }
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
    type.dispose();
    gender.dispose();
  }
}
