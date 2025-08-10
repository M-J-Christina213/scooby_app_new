import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pet.dart';

class PetService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<Pet>> fetchPetsForUser(String userId) async {
    try {
      print('[PetService] fetchPetsForUser called for userId: $userId');

      final ownerData = await supabase
          .from('pet_owners')
          .select('id')
          .eq('user_id', userId)
          .single();

      print('[PetService] pet_owner data: $ownerData');

      final String? petOwnerId = ownerData != null ? ownerData['id'] as String? : null;

      if (petOwnerId == null) {
        throw Exception('Pet owner not found for user ID: $userId');
      }

      final data = await supabase
          .from('pets')
          .select()
          .eq('user_id', petOwnerId)
          .order('created_at', ascending: false);

      print('[PetService] fetched pets count: ${data?.length ?? 0}');

      return (data as List<dynamic>)
          .map((e) => Pet.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      print('[PetService] fetchPetsForUser ERROR: $e\n$st');
      throw Exception('Failed to load pets: $e');
    }
  }

  Future<String?> uploadPetImage(String userId, String filePath, String fileName) async {
    try {
      print('[PetService] uploadPetImage called for userId: $userId, fileName: $fileName');

      await supabase.storage
          .from('pet-images')
          .upload('$userId/$fileName', File(filePath));

      final publicUrl = supabase.storage.from('pet-images').getPublicUrl('$userId/$fileName');
      print('[PetService] Image uploaded, public URL: $publicUrl');

      return publicUrl;
    } catch (e, st) {
      print('[PetService] uploadPetImage ERROR: $e\n$st');
      return null;
    }
  }

  Future<void> addPet(Pet pet, String authUserId) async {
    print('[PetService] addPet called for authUserId: $authUserId');
    try {
      final ownerData = await supabase
          .from('pet_owners')
          .select('id')
          .eq('user_id', authUserId)
          .single();

      print('[PetService] pet_owner data for addPet: $ownerData');

      final String? petOwnerId = ownerData != null ? ownerData['id'] as String? : null;

      if (petOwnerId == null) {
        final err = 'Pet owner not found for user ID: $authUserId';
        print('[PetService] ERROR: $err');
        throw Exception(err);
      }

      final petJson = pet.toJson(forInsert: true);
      petJson['user_id'] = petOwnerId;

      print('[PetService] Inserting pet: $petJson');

      await supabase.from('pets').insert([petJson]);

      print('[PetService] Pet added successfully');
    } catch (e, st) {
      print('[PetService] addPet ERROR: $e\n$st');
      rethrow;
    }
  }

  Future<void> updatePet(Pet pet, String authUserId) async {
    print('[PetService] updatePet called for authUserId: $authUserId, pet id: ${pet.id}');
    try {
      final ownerData = await supabase
          .from('pet_owners')
          .select('id')
          .eq('user_id', authUserId)
          .single();

      print('[PetService] pet_owner data for updatePet: $ownerData');

      final String? petOwnerId = ownerData != null ? ownerData['id'] as String? : null;

      if (petOwnerId == null) {
        final err = 'Pet owner not found for user ID: $authUserId';
        print('[PetService] ERROR: $err');
        throw Exception(err);
      }

      final petJson = pet.toJson(forInsert: true);
      petJson['user_id'] = petOwnerId;

      print('[PetService] Updating pet with data: $petJson');

      await supabase
          .from('pets')
          .update(petJson)
          .eq('id', pet.id)
          .eq('user_id', petOwnerId);

      print('[PetService] Pet updated successfully');
    } catch (e, st) {
      print('[PetService] updatePet ERROR: $e\n$st');
      rethrow;
    }
  }
}
