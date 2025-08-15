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
Future<void> updatePet(Pet pet, String authUserId) async {
  try {
    // Check if the user is a service provider first
    bool isServiceProvider = await _checkIfServiceProvider(authUserId);

    if (!isServiceProvider) {
      // If it's a pet owner, continue with the normal flow
      final ownerData = await supabase
          .from('pet_owners')
          .select('id')
          .eq('user_id', authUserId)
          .maybeSingle();

      final String? petOwnerId = ownerData?['id'] as String?;
      if (petOwnerId == null) {
        throw Exception("Pet owner not found for user_id: $authUserId");
      }

      final petJson = pet.toJson(forInsert: true);
      petJson['user_id'] = petOwnerId;

      await supabase
          .from('pets')
          .update(petJson)
          .eq('id', pet.id)
          .eq('user_id', petOwnerId);
    } else {
      // If it's a service provider, update directly with the service provider's user_id
      final petJson = pet.toJson(forInsert: true);
      petJson['user_id'] = authUserId; // Use service provider's user_id

      await supabase
          .from('pets')
          .update(petJson)
          .eq('id', pet.id)
          .eq('user_id', authUserId);
    }
  } catch (e) {
    rethrow;
  }
}

// Helper function to check if user is a service provider
Future<bool> _checkIfServiceProvider(String userId) async {
  final serviceProviderData = await supabase
      .from('service_providers') // assuming there's a `service_providers` table
      .select('id')
      .eq('user_id', userId)
      .maybeSingle();

  return serviceProviderData != null;
}

}