import 'dart:developer';
import 'dart:io';
import 'package:cross_file/cross_file.dart';
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
        // Convert File to XFile before upload
        final xfile = XFile(profileImage.path);
        imageUrl = await _uploadFile(
          bucketName: 'profile-images', // <-- Correct bucket here
          path: 'profile_images/${user.id}.jpg',
          file: xfile,
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
    required String phoneNo,
    required String email,
    required String password,
    required String address,
    required String city,
    required String role,
    required XFile? profileImage,
    required String clinicOrSalon,
    required List<XFile> galleryImages,
    required XFile? qualificationFile,
    required XFile? idVerificationFile,
    required String experience,
    required String serviceDescription,
    required String notes,
    required String pricingDetails,
    required String consultationFee,
    required String aboutClinicOrSalon,
    required List<String> groomingServices,
    required List<String> comfortableWith,
    required String availableTimes,
    required String dislikes,
    required String rate,
  }) async {
    final uuid = Uuid();
    try {
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final userId = authResponse.user?.id;
      if (userId == null) {
        throw Exception('Failed to get user ID');
      }

      // Upload profile image
      String? profileImageUrl;
      if (profileImage != null) {
        profileImageUrl = await _uploadFile(
          bucketName: 'profile-images', // <-- Correct bucket here
          path: 'profile_images/$userId.jpg',
          file: profileImage,
          contentType: 'image/jpeg',
        );
      }

      // Upload qualification file
      String? qualificationUrl;
      if (qualificationFile != null) {
        final fileExt = qualificationFile.path.split('.').last;
        qualificationUrl = await _uploadFile(
          bucketName: 'qualifications', // <-- Correct bucket here
          path: 'qualifications/$userId.$fileExt',
          file: qualificationFile,
          contentType: 'application/pdf',
        );
      }

      // Upload ID verification file
      String? idVerificationUrl;
      if (idVerificationFile != null) {
        final fileExt = idVerificationFile.path.split('.').last;
        idVerificationUrl = await _uploadFile(
          bucketName: 'verifications', // <-- Correct bucket here
          path: 'id_verifications/$userId.$fileExt',
          file: idVerificationFile,
          contentType: 'application/pdf',
        );
      }

      // Upload gallery images
      List<String> galleryUrls = [];
      for (XFile img in galleryImages) {
        final fileExt = img.path.split('.').last;
        final fileName = '${uuid.v4()}.$fileExt';
        final url = await _uploadFile(
          bucketName: 'gallery-images', // <-- Correct bucket here
          path: 'provider-galleries/$userId/$fileName',
          file: img,
          contentType: 'image/jpeg',
        );
        galleryUrls.add(url);
      }

      // Insert into database
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
        'image_url': profileImageUrl,
        'qualification_url': qualificationUrl,
        'id_verification_url': idVerificationUrl,
        'gallery_urls': galleryUrls,
        'clinic_or_salon_name': clinicOrSalon,
        'availability': availableTimes,
        'notes': notes,
        'pricing_details': pricingDetails,
        'consultation_fee': consultationFee,
        'about_clinic_or_salon': aboutClinicOrSalon,
        'grooming_services': groomingServices,
        'comfortable_with': comfortableWith,
        'dislikes': dislikes,
        'rate': rate,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      log('Registration error: $e');
      rethrow;
    }
  }

  Future<String> _uploadFile({
    required String bucketName,
    required String path,
    required XFile file,
    required String contentType,
  }) async {
    final bytes = await file.readAsBytes();

    await _supabase.storage.from(bucketName).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: true,
          ),
        );

    return _supabase.storage.from(bucketName).getPublicUrl(path);
  }  // File upload to Supabase Storage

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
