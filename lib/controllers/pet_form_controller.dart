// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scooby_app_new/controllers/pet_service.dart';
import 'package:scooby_app_new/models/pet.dart';
import 'package:uuid/uuid.dart';

class PetFormController {
  final PetService petService;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController breedController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController foodController = TextEditingController();
  final TextEditingController moodController = TextEditingController();
  final TextEditingController healthController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final ValueNotifier<String?> type = ValueNotifier(null);
  final ValueNotifier<String?> gender = ValueNotifier(null);

  final List<TextEditingController> medicalControllers = [];

  File? imageFile;
  bool _isSaving = false;
  bool get isSaving => _isSaving;

  final uuid = Uuid();

  PetFormController({Pet? existingPet, required this.petService}) {
    if (existingPet != null) {
      nameController.text = existingPet.name;
      ageController.text = existingPet.age.toString();
      breedController.text = existingPet.breed;
      colorController.text = existingPet.color ?? '';
      weightController.text = existingPet.weight?.toString() ?? '';
      heightController.text = existingPet.height?.toString() ?? '';
      foodController.text = existingPet.foodPreference ?? '';
      moodController.text = existingPet.mood ?? '';
      healthController.text = existingPet.healthStatus ?? '';
      descriptionController.text = existingPet.description ?? '';
      type.value = existingPet.type;
      gender.value = existingPet.gender;

      if (existingPet.medicalHistory != null && existingPet.medicalHistory!.isNotEmpty) {
        for (var record in existingPet.medicalHistory!.split(',')) {
          medicalControllers.add(TextEditingController(text: record));
        }
      } else {
        medicalControllers.add(TextEditingController());
      }
    } else {
      medicalControllers.add(TextEditingController());
    }
  }

  void addMedicalRecord() {
    medicalControllers.add(TextEditingController());
  }

  void removeMedicalRecord(int index) {
    if (index >= 0 && index < medicalControllers.length) {
      medicalControllers[index].dispose();
      medicalControllers.removeAt(index);
    }
  }

  ImageProvider? get imageProvider {
    if (imageFile != null) return FileImage(imageFile!);
    return null;
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      imageFile = File(picked.path);
    }
  }

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
    return true;
  }

  Future<bool> savePet(String authUserId, BuildContext context, {String? existingId}) async {
    if (!validate(context)) return false;

    _isSaving = true;

    try {
      String? imageUrl;
      if (imageFile != null) {
        final fileName = '${uuid.v4()}.jpg';
        imageUrl = await petService.uploadPetImage(authUserId, imageFile!.path, fileName);
      }

      final medicalRecordsString = medicalControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .join(',');

      final petId = existingId ?? uuid.v4();

      final pet = Pet(
        id: petId,
        userId: authUserId,
        name: nameController.text.trim(),
        type: type.value ?? '',
        breed: breedController.text.trim(),
        age: int.tryParse(ageController.text.trim()) ?? 0,
        gender: gender.value ?? '',
        color: colorController.text.trim().isEmpty ? null : colorController.text.trim(),
        weight: double.tryParse(weightController.text.trim()),
        height: double.tryParse(heightController.text.trim()),
        medicalHistory: medicalRecordsString.isEmpty ? null : medicalRecordsString,
        foodPreference: foodController.text.trim().isEmpty ? null : foodController.text.trim(),
        mood: moodController.text.trim().isEmpty ? null : moodController.text.trim(),
        healthStatus: healthController.text.trim().isEmpty ? null : healthController.text.trim(),
        description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
        imageUrl: imageUrl,
        createdAt: null,
      );

      if (existingId == null) {
        await petService.addPet(pet, authUserId);
      } else {
        await petService.updatePet(pet, authUserId);
      }

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
    foodController.dispose();
    moodController.dispose();
    healthController.dispose();
    descriptionController.dispose();
    type.dispose();
    gender.dispose();
    for (var c in medicalControllers) {
      c.dispose();
    }
  }
}

