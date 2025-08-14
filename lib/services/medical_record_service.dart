


// ignore_for_file: unused_import

import 'package:scooby_app_new/models/medical_records.dart';
import 'package:scooby_app_new/views/screens/pet_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class MedicalRecordService {
  Future<List<Vaccination>> listVaccinations(String petId);
  Future<String> addVaccination(Vaccination v);
  Future<void> updateVaccination(String id, Vaccination v);
  Future<void> deleteVaccination(String id);

  Future<List<MedicalCheckup>> listCheckups(String petId);
  Future<String> addCheckup(MedicalCheckup c);
  Future<void> updateCheckup(String id, MedicalCheckup c);
  Future<void> deleteCheckup(String id);

  Future<List<Prescription>> listPrescriptions(String petId);
  Future<String> addPrescription(Prescription p);
  Future<void> updatePrescription(String id, Prescription p);
  Future<void> deletePrescription(String id);
}

class SupabaseMedicalRecordService implements MedicalRecordService {
  final SupabaseClient _sb;
  SupabaseMedicalRecordService(this._sb);

  @override
  Future<List<Vaccination>> listVaccinations(String petId) async {
    final res = await _sb.from('vaccinations')
        .select()
        .eq('pet_id', petId)
        .order('date_given', ascending: false);
    return (res as List).map((m) => Vaccination.fromMap(m as Map<String, dynamic>)).toList();
  }

  @override
  Future<String> addVaccination(Vaccination v) async {
    final res = await _sb.from('vaccinations').insert(v.toInsert()).select('id').single();
    return res['id'] as String;
  }

  @override
  Future<void> updateVaccination(String id, Vaccination v) async {
    await _sb.from('vaccinations').update(v.toUpdate()).eq('id', id);
  }

  @override
  Future<void> deleteVaccination(String id) async {
    await _sb.from('vaccinations').delete().eq('id', id);
  }

  @override
  Future<List<MedicalCheckup>> listCheckups(String petId) async {
    final res = await _sb.from('medical_checkups')
        .select()
        .eq('pet_id', petId)
        .order('date', ascending: false);
    return (res as List).map((m) => MedicalCheckup.fromMap(m as Map<String, dynamic>)).toList();
  }

  @override
  Future<String> addCheckup(MedicalCheckup c) async {
    final res = await _sb.from('medical_checkups').insert(c.toInsert()).select('id').single();
    return res['id'] as String;
  }

  @override
  Future<void> updateCheckup(String id, MedicalCheckup c) async {
    await _sb.from('medical_checkups').update(c.toUpdate()).eq('id', id);
  }

  @override
  Future<void> deleteCheckup(String id) async {
    await _sb.from('medical_checkups').delete().eq('id', id);
  }

  @override
  Future<List<Prescription>> listPrescriptions(String petId) async {
    final res = await _sb.from('prescriptions')
        .select()
        .eq('pet_id', petId)
        .order('start_date', ascending: false);
    return (res as List).map((m) => Prescription.fromMap(m as Map<String, dynamic>)).toList();
  }

  @override
  Future<String> addPrescription(Prescription p) async {
    final res = await _sb.from('prescriptions').insert(p.toInsert()).select('id').single();
    return res['id'] as String;
  }

  @override
  Future<void> updatePrescription(String id, Prescription p) async {
    await _sb.from('prescriptions').update(p.toUpdate()).eq('id', id);
  }

  @override
  Future<void> deletePrescription(String id) async {
    await _sb.from('prescriptions').delete().eq('id', id);
  }
}
