import 'dart:developer';
import 'dart:io';
import 'package:scooby_app_new/views/service_provider_home.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

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
  Future<void> registerServiceProvider({
    required String name,
    required String email,
    required String password,
    required String phoneNo,
    required String address,
    required String city,
    required String role,
    required String serviceDescription,
    required String experience,
    File? qualificationFile,
    List<File>? galleryImages,
    String? clinicOrSalon,
    String? availability,
    String? notes,
  }) async {
    final uuid = Uuid();
    try {
      // Sign up the user
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final userId = authResponse.user?.id;
      if (userId == null) {
        throw Exception('Failed to get user ID');
      }

      // Upload qualification file (if provided)
      String? qualificationUrl;
      if (qualificationFile != null) {
        final fileExt = qualificationFile.path.split('.').last;
        final filePath = 'qualifications/$userId.$fileExt';

        await _supabase.storage
            .from('scooby_bucket')
            .upload(filePath, qualificationFile);

        qualificationUrl = _supabase.storage
            .from('scooby_bucket')
            .getPublicUrl(filePath);
      }

      // Upload gallery images (if provided)
      List<String> galleryUrls = [];
      if (galleryImages != null && galleryImages.isNotEmpty) {
        for (File img in galleryImages) {
          final fileName = '${uuid.v4()}.${img.path.split('.').last}';
          final filePath = 'provider-galleries/$userId/$fileName';

          await _supabase.storage
              .from('scooby_bucket')
              .upload(filePath, img);

          final url = _supabase.storage
              .from('scooby_bucket')
              .getPublicUrl(filePath);

          galleryUrls.add(url);
        }
      }

      // Insert into service_providers table
      await _supabase.from('service_providers').insert({
        'user_id': userId,
        'name': name,
        'email': email,
        'password': password,
        'phone_no': phoneNo,
        'address': address,
        'city': city,
        'role': role,
        'service_description': serviceDescription,
        'experience': experience,
        'qualification_url': qualificationUrl,
        'gallery_urls': galleryUrls,
        'clinic_or_salon_name': clinicOrSalon,
        'availability': availability,
        'notes': notes,
      });
    } catch (e) {
      print('Registration error: $e');
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

  // Get Service Provider Email
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
