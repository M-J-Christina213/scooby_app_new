import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pet.dart';

class PetService {
  static final PetService instance = PetService();
  final SupabaseClient supabase = Supabase.instance.client;

  // Fetch pets for a given user
  Future<List<Pet>> fetchPetsForUser(String userId) async {
    try {
      final ownerData = await supabase
          .from('pet_owners')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

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

  // Upload pet image
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

  // Add a new pet
  Future<void> addPet(Pet pet, String authUserId) async {
    try {
      final ownerData = await supabase
          .from('pet_owners')
          .select('id')
          .eq('user_id', authUserId)
          .maybeSingle();

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

  // Update pet details
  Future<void> updatePet(Pet pet, String petOwnerId) async {
    try {
      // Fetch the actual auth user_id for this pet owner
      final ownerData = await supabase
          .from('pet_owners')
          .select('user_id')
          .eq('id', petOwnerId) 
          .maybeSingle();

      final String? authUserId = ownerData?['user_id'] as String?;
      if (authUserId == null) throw Exception("User ID not found");

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
