// lib/controllers/pet_service.dart

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pet.dart';
class PetService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<Pet>> fetchPetsForUser(String userId) async {
    try {
      // First get pet_owner.id by userId
      final ownerData = await supabase
          .from('pet_owners')
          .select('id')
          .eq('user_id', userId)
          .single();

      final String? petOwnerId = ownerData != null ? ownerData['id'] as String? : null;

      if (petOwnerId == null) {
        throw Exception('Pet owner not found for user ID: $userId');
      }

      final data = await supabase
          .from('pets')
          .select()
          .eq('user_id', petOwnerId)
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

  Future<void> addPet(Pet pet, String authUserId) async {
    // Get pet_owner.id from pet_owners table using authUserId
    final ownerData = await supabase
        .from('pet_owners')
        .select('id')
        .eq('user_id', authUserId)
        .single();

    final String? petOwnerId = ownerData != null ? ownerData['id'] as String? : null;

    if (petOwnerId == null) {
      throw Exception('Pet owner not found for user ID: $authUserId');
    }

    // Assign the petOwnerId as user_id in pets table
    final petJson = pet.toJson();
    petJson['user_id'] = petOwnerId;

    final response = await supabase.from('pets').insert([petJson]);

    if (response.error != null) {
      throw Exception('Failed to add pet: ${response.error!.message}');
    }
  }
}
