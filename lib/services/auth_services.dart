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

  // Get Pet Owner ID by Auth ID
  Future<String?> getPetOwnerIdFromAuthId(String authUserId) async {
    final data = await _supabase
        .from('pet_owners')
        .select('id')
        .eq('user_id', authUserId)
        .maybeSingle();
    return data?['id'] as String?;
  }

  // Get Pet Owner City by Auth ID
  Future<String?> getPetOwnerCityFromAuthId(String authUserId) async {
    final response = await _supabase
        .from('pet_owners')
        .select('city')
        .eq('user_id', authUserId)
        .maybeSingle();

    if (response == null || response['city'] == null) {
      return null;
    }

    return response['city'] as String;
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
        final xfile = XFile(profileImage.path);
        imageUrl = await _uploadFile(
          bucketName: 'profile-images',
          path: 'pet_owners/${user.id}.jpg',
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
    required String city,
    required String role,
    required XFile? profileImage,
    required String clinicOrSalonName,
    required String clinicOrSalonAddress,
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
    final supabase = _supabase;

    try {
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      final userId = authResponse.user?.id;
      if (userId == null) {
        throw Exception('User signup failed. No user ID returned.');
      }

      String sanitize(String input) => input.replaceAll('\u0000', '');

      String? profileImageUrl;
      if (profileImage != null) {
        profileImageUrl = await _uploadFile(
          bucketName: 'profile-images',
          path: 'service_providers/$userId.jpg',
          file: profileImage,
          contentType: 'image/jpeg',
        );
      }

      String? qualificationUrl;
      if (qualificationFile != null) {
        final ext = qualificationFile.path.split('.').last;
        qualificationUrl = await _uploadFile(
          bucketName: 'qualifications',
          path: 'qualifications/$userId.$ext',
          file: qualificationFile,
          contentType: 'application/pdf',
        );
      }

      String? idVerificationUrl;
      if (idVerificationFile != null) {
        final ext = idVerificationFile.path.split('.').last;
        idVerificationUrl = await _uploadFile(
          bucketName: 'verifications',
          path: 'verifications/$userId.$ext',
          file: idVerificationFile,
          contentType: 'application/pdf',
        );
      }

      List<String> galleryUrls = [];
      for (XFile img in galleryImages) {
        final ext = img.path.split('.').last;
        final fileName = '${uuid.v4()}.$ext';
        final url = await _uploadFile(
          bucketName: 'gallery-images',
          path: 'provider-galleries/$userId/$fileName',
          file: img,
          contentType: 'image/jpeg',
        );
        galleryUrls.add(url);
      }

      final response = await supabase
          .from('service_providers')
          .insert([
            {
              'user_id': userId,
              'name': sanitize(name),
              'email': sanitize(email),
              'phone_no': sanitize(phoneNo),
              'city': sanitize(city),
              'role': sanitize(role),
              'service_description': sanitize(serviceDescription),
              'experience': sanitize(experience),
              'profile_image_url': profileImageUrl,
              'qualification_url': qualificationUrl,
              'verification_url': idVerificationUrl,
              'gallery_images': galleryUrls,
              'clinic_or_salon_name': sanitize(clinicOrSalonName),
              'clinic_or_salon_address': sanitize(clinicOrSalonAddress),
              'available_times': sanitize(availableTimes),
              'notes': sanitize(notes),
              'pricing_details': sanitize(pricingDetails),
              'consultation_fee': sanitize(consultationFee),
              'about_clinic_salon': sanitize(aboutClinicOrSalon),
              'grooming_services': groomingServices,
              'comfortable_with': comfortableWith,
              'dislikes': sanitize(dislikes),
              'rate': sanitize(rate),
              'created_at': DateTime.now().toUtc().toIso8601String(),
            }
          ])
          .select()
          .maybeSingle();

      if (response == null) {
        throw Exception('Failed to insert service provider into database.');
      }

      log('✅ Service Provider registered successfully: $userId');
    } catch (e, st) {
      log('❌ Register ServiceProvider Error: $e\n$st');
      rethrow;
    }
  }

  // Upload File to Supabase Storage
  Future<String> _uploadFile({
    required String bucketName,
    required String path,
    required XFile file,
    required String contentType,
  }) async {
    final bytes = await file.readAsBytes();

    try {
      await _supabase.storage.from(bucketName).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );
    } catch (e) {
      log('Upload failed for $bucketName/$path: $e');
      rethrow;
    }

    final url = _supabase.storage.from(bucketName).getPublicUrl(path);
    log('File uploaded to $url');
    return url;
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
  Future<String> getUserRole(String userId) async {
    final supabase = _supabase;

    final provider = await supabase
        .from('service_providers')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();
    if (provider != null) return 'service_provider';

    final owner = await supabase
        .from('pet_owners')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();
    if (owner != null) return 'pet_owner';

    return 'unknown';
  }
}
