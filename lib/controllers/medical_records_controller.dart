import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scooby_app_new/models/medical_records.dart';
import 'package:scooby_app_new/services/medical_record_service.dart';

class MedicalRecordsController with ChangeNotifier {
  final MedicalRecordService service;
  final String petId;

  MedicalRecordsController({required this.service, required this.petId});

  final df = DateFormat('yyyy-MM-dd');

  List<Vaccination> vaccinations = [];
  List<MedicalCheckup> checkups = [];
  List<Prescription> prescriptions = [];

  bool loadingVacc = false;
  bool loadingCheck = false;
  bool loadingRx = false;

  Future<void> loadAll() async {
    await Future.wait([
      loadVaccinations(),
      loadCheckups(),
      loadPrescriptions(),
    ]);
  }

  Future<void> loadVaccinations() async {
    loadingVacc = true; notifyListeners();
    try {
      vaccinations = await service.listVaccinations(petId);
    } finally {
      loadingVacc = false; notifyListeners();
    }
  }

  Future<void> loadCheckups() async {
    loadingCheck = true; notifyListeners();
    try {
      checkups = await service.listCheckups(petId);
    } finally {
      loadingCheck = false; notifyListeners();
    }
  }

  Future<void> loadPrescriptions() async {
    loadingRx = true; notifyListeners();
    try {
      prescriptions = await service.listPrescriptions(petId);
    } finally {
      loadingRx = false; notifyListeners();
    }
  }

  Future<void> addOrUpdateVaccination({
    Vaccination? existing,
    required String name,
    String? desc,
    required DateTime dateGiven,
    DateTime? nextDue,
    String? createdBy, // camelCase
  }) async {
    if (existing == null) {
      await service.addVaccination(
        Vaccination(
          id: '',
          petId: petId,
          vaccinationName: name,
          description: desc,
          dateGiven: dateGiven,
          nextDueDate: nextDue,
          createdBy: createdBy,
        ),
      );
    } else {
      await service.updateVaccination(
        existing.id,
        Vaccination(
          id: existing.id,
          petId: existing.petId,
          vaccinationName: name,
          description: desc,
          dateGiven: dateGiven,
          nextDueDate: nextDue,
          createdBy: createdBy ?? existing.createdBy,
        ),
      );
    }
    await loadVaccinations();
  }

  Future<void> deleteVaccination(String id) async {
    await service.deleteVaccination(id);
    await loadVaccinations();
  }

  Future<void> addOrUpdateCheckup({
    MedicalCheckup? existing,
    required String reason,
    String? desc,
    required DateTime date,
    String? createdBy, // camelCase
  }) async {
    if (existing == null) {
      await service.addCheckup(
        MedicalCheckup(
          id: '',
          petId: petId,
          reason: reason,
          description: desc,
          date: date,
          createdBy: createdBy,
        ),
      );
    } else {
      await service.updateCheckup(
        existing.id,
        MedicalCheckup(
          id: existing.id,
          petId: existing.petId,
          reason: reason,
          description: desc,
          date: date,
          createdBy: createdBy ?? existing.createdBy,
        ),
      );
    }
    await loadCheckups();
  }

  Future<void> deleteCheckup(String id) async {
    await service.deleteCheckup(id);
    await loadCheckups();
  }

  Future<void> addOrUpdatePrescription({
    Prescription? existing,
    required String med,
    String? desc,
    required DateTime start,
    DateTime? end,
    String? createdBy, // camelCase
  }) async {
    if (existing == null) {
      await service.addPrescription(
        Prescription(
          id: '',
          petId: petId,
          medicineName: med,
          description: desc,
          startDate: start,
          endDate: end,
          createdBy: createdBy,
        ),
      );
    } else {
      await service.updatePrescription(
        existing.id,
        Prescription(
          id: existing.id,
          petId: existing.petId,
          medicineName: med,
          description: desc,
          startDate: start,
          endDate: end,
          createdBy: createdBy ?? existing.createdBy,
        ),
      );
    }
    await loadPrescriptions();
  }

  Future<void> deletePrescription(String id) async {
    await service.deletePrescription(id);
    await loadPrescriptions();
  }
}
