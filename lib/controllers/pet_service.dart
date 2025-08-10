import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pet.dart';

class PetService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<Pet>> fetchPetsForUser(String userId) async {
    try {
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
      await supabase.storage
          .from('pet-images')
          .upload('$userId/$fileName', File(filePath));

      final publicUrl = supabase.storage.from('pet-images').getPublicUrl('$userId/$fileName');

      return publicUrl;
    } catch (e) {
      return null;
    }
  }

  Future<void> addPet(Pet pet, String authUserId) async {
    try {
      final ownerData = await supabase
          .from('pet_owners')
          .select('id')
          .eq('user_id', authUserId)
          .single();

      final String? petOwnerId = ownerData != null ? ownerData['id'] as String? : null;

      if (petOwnerId == null) {
        throw Exception('Pet owner not found for user ID: $authUserId');
      }

      final petJson = pet.toJson(forInsert: true);
      petJson['user_id'] = petOwnerId;

      await supabase.from('pets').insert([petJson]);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePet(Pet pet, String authUserId) async {
    try {
      final ownerData = await supabase
          .from('pet_owners')
          .select('id')
          .eq('user_id', authUserId)
          .single();

      final String? petOwnerId = ownerData != null ? ownerData['id'] as String? : null;

      if (petOwnerId == null) {
        throw Exception('Pet owner not found for user ID: $authUserId');
      }

      final petJson = pet.toJson(forInsert: true);
      petJson['user_id'] = petOwnerId;

      await supabase
          .from('pets')
          .update(petJson)
          .eq('id', pet.id)
          .eq('user_id', petOwnerId);
    } catch (e) {
      rethrow;
    }
  }
}
