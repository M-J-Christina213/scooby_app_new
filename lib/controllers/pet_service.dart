// lib/controllers/pet_service.dart

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pet.dart';

class PetService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<Pet>> fetchPetsForUser(String userId) async {
    try {
      final data = await supabase
          .from('pets')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (data as List<dynamic>)
          .map((e) => Pet.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load pets: $e');
    }
  }

  Future<String?> uploadPetImage(String userId, String filePath, String fileName) async {
    try {
      final String _ = await supabase.storage
          .from('pet-images')
          .upload('$userId/$fileName', File(filePath));

      final publicUrl = supabase.storage.from('pet-images').getPublicUrl('$userId/$fileName');
      return publicUrl;
    } catch (e) {
     ('Upload error: $e');
      return null;
    }
  }

  Future<void> addPet(Pet pet) async {
    final response = await supabase.from('pets').insert([pet.toJson()]);
    if (response.error != null) {
      throw Exception('Failed to add pet: ${response.error!.message}');
    }
  }
}
