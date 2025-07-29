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

      String? imageUrl;
      if (user != null && profileImage != null) {
        imageUrl = await _uploadFile(
          path: 'profile_images/${user.id}.jpg',
          file: profileImage,
          contentType: 'image/jpeg',
        );
      }

      await _supabase.from('pet_owners').insert({
        'uid': user?.id,
        'role': 'pet_owner',
        'name': name,
        'phone': phone,
        'address': address,
        'city': city,
        'email': email,
        'image_url': imageUrl,
        'created_at': DateTime.now().toIso8601String(),
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
    File? qualificationFile,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      final user = response.user;

      String? imageUrl;
      String? qualificationUrl;

      if (user != null && profileImage != null) {
        imageUrl = await _uploadFile(
          path: 'profile_images/${user.id}.jpg',
          file: profileImage,
          contentType: 'image/jpeg',
        );
      }

      if (user != null && qualificationFile != null) {
        final fileName = qualificationFile.path.split('/').last;
        qualificationUrl = await _uploadFile(
          path: 'qualifications/${user.id}-$fileName',
          file: qualificationFile,
          contentType: 'application/pdf', 
        );
      }

      await _supabase.from('service_providers').insert({
        'uid': user?.id,
        'role': 'service_provider',
        'name': name,
        'provider_role': role,
        'phone': phone,
        'address': address,
        'city': city,
        'email': email,
        'description': description,
        'experience': experience,
        'image_url': imageUrl,
        'qualification_url': qualificationUrl,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      return user;
    } catch (e) {
      log('Register ServiceProvider Error: $e');
      rethrow;
    }
  }

  // File upload to Supabase Storage
Future<String> _uploadFile({
  required String path, // e.g., 'pet_owners/uid.jpg'
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


  // Check User Role
  Future<String?> getUserRole(String uid) async {
    final petOwner = await _supabase
        .from('pet_owners')
        .select('uid')
        .eq('uid', uid)
        .maybeSingle();

    if (petOwner != null) return 'pet_owner';

    final provider = await _supabase
        .from('service_providers')
        .select('uid')
        .eq('uid', uid)
        .maybeSingle();

    if (provider != null) return 'service_provider';

    return null;
  }
}
