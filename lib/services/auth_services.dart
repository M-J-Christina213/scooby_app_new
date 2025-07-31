import 'dart:developer';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Sign In Method
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user;
    } catch (e) {
      log('Login Error: $e');
      rethrow;
    }
  }

  // Register Pet Owner
  Future<User?> registerPetOwner({
    required String name,
    required String phone,
    required String address,
    required String city,
    required String email,
    required String password,
    File? profileImage,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      final user = response.user;

      if (user == null) throw Exception("User creation failed");

      String? imageUrl;
      if (profileImage != null) {
        imageUrl = await _uploadFile(
          path: 'profile_images/${user.id}.jpg',
          file: profileImage,
          contentType: 'image/jpeg',
        );
      }

      await _supabase.from('pet_owners').insert({
        'user_id': user.id, 
        'name': name,
        'phone_number': phone,
        'address': address,
        'city': city,
        'email': email,
        'image_url': imageUrl,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      return user;
    } catch (e) {
      log('Register PetOwner Error: $e');
      rethrow;
    }
  }

  // Register Service Provider
  Future<User?> registerServiceProvider({
    required String name,
    required String role,
    required String phone,
    required String address,
    required String city,
    required String email,
    required String password,
    required String description,
    required String experience,
    File? profileImage,
    // Ignoring qualification file for now as not in schema
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      final user = response.user;

      if (user == null) throw Exception("User creation failed");

      String? imageUrl;

      if (profileImage != null) {
        imageUrl = await _uploadFile(
          path: 'profile_images/${user.id}.jpg',
          file: profileImage,
          contentType: 'image/jpeg',
        );
      }

      await _supabase.from('service_providers').insert({
        'user_id': user.id, 
        'name': name,
        'role': role, 
        'phone_no': phone, 
        'address': address,
        'city': city,
        'email': email,
        'service_description': description, 
        'experience': experience,
        'image_url': imageUrl,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        // Note: password is NOT needed in this table, already handled by auth
      });

      return user;
    } catch (e) {
      log('Register ServiceProvider Error: $e');
      rethrow;
    }
  }

  // File upload to Supabase Storage
  Future<String> _uploadFile({
    required String path, 
    required File file,
    required String contentType,
  }) async {
    final bytes = await file.readAsBytes();

    await _supabase.storage
        .from('profile-images')
        .uploadBinary(path, bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true));

    final publicUrl = _supabase.storage
        .from('profile-images')
        .getPublicUrl(path);

    return publicUrl;
  }

Future<String?> getServiceProviderEmail(String uid) async {
  final response = await _supabase
      .from('service_providers')
      .select('email')
      .eq('user_id', uid)
      .maybeSingle();

  if (response == null || response['email'] == null) return null;

  return response['email'] as String?;
}








  // Check User Role
  Future<String?> getUserRole(String uid) async {
    final petOwner = await _supabase
        .from('pet_owners')
        .select('user_id')
        .eq('user_id', uid)
        .maybeSingle();

    if (petOwner != null) return 'pet_owner';

    final provider = await _supabase
        .from('service_providers')
        .select('user_id')
        .eq('user_id', uid)
        .maybeSingle();

    if (provider != null) return 'service_provider';

    return null;
  }
}
