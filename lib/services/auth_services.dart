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
        final xfile = XFile(profileImage.path);
        // Upload to 'pet_owners' folder for pet owner profile images
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

      // Upload profile image - inside 'service_providers' folder
      String? profileImageUrl;
      if (profileImage != null) {
        profileImageUrl = await _uploadFile(
          bucketName: 'profile-images',
          path: 'service_providers/$userId.jpg',
          file: profileImage,
          contentType: 'image/jpeg',
        );
      }

      // Upload qualification file
      String? qualificationUrl;
      if (qualificationFile != null) {
        final fileExt = qualificationFile.path.split('.').last;
        qualificationUrl = await _uploadFile(
          bucketName: 'qualifications',
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
          bucketName: 'verifications',
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
          bucketName: 'gallery-images',
          path: 'provider-galleries/$userId/$fileName',
          file: img,
          contentType: 'image/jpeg',
        );
        galleryUrls.add(url);
      }

      String sanitizeInput(String input) {
        return input.replaceAll('\u0000', '');
      }

      // Insert into database
      await _supabase.from('service_providers').insert({
        'user_id': userId,
        'name': sanitizeInput(name),
        'email': sanitizeInput(email),
        'password': sanitizeInput(password),
        'phone_no': sanitizeInput(phoneNo),
        'address': sanitizeInput(address), 
        'city': sanitizeInput(city),
        'role': sanitizeInput(role),
        'service_description': sanitizeInput(serviceDescription),
        'experience': sanitizeInput(experience),
        'profile_image_url': profileImageUrl != null ? sanitizeInput(profileImageUrl) : null,
        'qualification_url': qualificationUrl != null ? sanitizeInput(qualificationUrl) : null,
        'verification_url': idVerificationUrl != null ? sanitizeInput(idVerificationUrl) : null,
        'gallery_images': galleryUrls.map(sanitizeInput).toList(),
        'clinic_or_salon': sanitizeInput(clinicOrSalon),
        'available_times': sanitizeInput(availableTimes),
        'notes': sanitizeInput(notes),
        'pricing_details': sanitizeInput(pricingDetails),
        'consultation_fee': sanitizeInput(consultationFee),
        'about_clinic_salon': sanitizeInput(aboutClinicOrSalon),
        'grooming_services': groomingServices.map(sanitizeInput).toList(),
        'comfortable_with': comfortableWith.map(sanitizeInput).toList(),
        'dislikes': sanitizeInput(dislikes),
        'rate': sanitizeInput(rate),
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
