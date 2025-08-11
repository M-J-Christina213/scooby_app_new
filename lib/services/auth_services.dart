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
 
Future<String?> getPetOwnerIdFromAuthId(String authUserId) async {
  final data = await Supabase.instance.client
      .from('pet_owners')
      .select('id')
      .eq('user_id', authUserId) // match auth.users.id to pet_owners.user_id
      .maybeSingle();

  return data?['id'] as String?;
}

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
  try {
    // 1️⃣ Create the Auth user
    final authResponse = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    final userId = authResponse.user?.id;
    if (userId == null) {
      throw Exception('Failed to get user ID from sign-up.');
    }

    // 2️⃣ Optional small pause for propagation
    await Future.delayed(const Duration(milliseconds: 300));

    // 3️⃣ Upload files as before...
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

    String sanitize(String input) => input.replaceAll('\u0000', '');

   // 4️⃣ Insert into database with error handling
final response = await _supabase
    .from('service_providers')
    .insert([
      {
        'user_id': userId,
        'name': sanitize(name),
        'email': sanitize(email),
        'password': sanitize(password),
        'phone_no': sanitize(phoneNo),
        'city': sanitize(city),
        'role': sanitize(role),
        'service_description': sanitize(serviceDescription),
        'experience': sanitize(experience),
        'profile_image_url': profileImageUrl != null ? sanitize(profileImageUrl) : null,
        'qualification_url': qualificationUrl != null ? sanitize(qualificationUrl) : null,
        'verification_url': idVerificationUrl != null ? sanitize(idVerificationUrl) : null,
        'gallery_images': galleryUrls.map(sanitize).toList(),
        'clinic_or_salon_name': sanitize(clinicOrSalonName),
        'clinic_or_salon_address': sanitize(clinicOrSalonAddress),
        'available_times': sanitize(availableTimes),
        'notes': sanitize(notes),
        'pricing_details': sanitize(pricingDetails),
        'consultation_fee': sanitize(consultationFee),
        'about_clinic_salon': sanitize(aboutClinicOrSalon),
        'grooming_services': groomingServices.map(sanitize).toList(),
        'comfortable_with': comfortableWith.map(sanitize).toList(),
        'dislikes': sanitize(dislikes),
        'rate': sanitize(rate),
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }
    ])
    .select()
    .maybeSingle();

if (response == null) {
  log('Supabase insert error: Insert returned null');
  throw Exception('Failed to insert service provider');
}
    log('Service Provider registered successfully: $userId');
  } catch (e) {
    log('Register ServiceProvider Error: $e');
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
