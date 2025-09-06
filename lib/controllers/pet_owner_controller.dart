// lib/controllers/pet_owner_controller.dart
import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PetOwnerController {
  final SupabaseClient _sb = Supabase.instance.client;

  // ── keep if your app still calls this; otherwise you can remove ─────────────
  Future register({
    required String name,
    required String phone,
    required String address,
    required String city,
    required String email,
    required String password,
  }) {
    // Your project previously delegated this to AuthService.registerPetOwner.
    // Leave as-is or wire it back to AuthService if you use it elsewhere.
    return Supabase.instance.client.functions.invoke('noop'); // placeholder
  }
  // ─────────────────────────────────────────────────────────────────────────────

  /// Fetch current owner's row from `pet_owners` using auth.user.id.
  Future<Map<String, dynamic>?> fetchCurrentOwner() async {
    final user = _sb.auth.currentUser;
    if (user == null) return null;

    final row = await _sb
        .from('pet_owners')
        .select('id, user_id, name, email, phone_number, address, city, image_url, created_at')
        .eq('user_id', user.id)
        .maybeSingle();

    return row;
  }

  /// True if [email] is not used by someone else (or belongs to the current user).
  Future<bool> isEmailAvailable(String email) async {
    final user = _sb.auth.currentUser;
    if (user == null) return false;

    final target = email.trim().toLowerCase();
    final row = await _sb
        .from('pet_owners')
        .select('user_id')
        .eq('email', target)
        .limit(1)
        .maybeSingle();

    // No row => free to use
    if (row == null) return true;

    // If the row belongs to me, also ok
    final ownerUserId = row['user_id'] as String?;
    return ownerUserId == user.id;
  }

  /// Update current owner's profile.
  /// - Uploads [newProfileImage] to `profile-images/pet_owners/<userId>.jpg` (upsert).
  /// - If [newEmail] provided and different, checks availability and updates Auth + table.
  /// Returns the new public image URL if changed, else null.
  Future<String?> updateCurrentOwner({
    required String name,
    required String phone,
    required String address,
    required String city,
    String? newEmail,
    XFile? newProfileImage,
  }) async {
    final user = _sb.auth.currentUser;
    if (user == null) {
      throw Exception('Not logged in');
    }

    String? imageUrl;
    if (newProfileImage != null) {
      final Uint8List bytes = await newProfileImage.readAsBytes();
      final path = 'pet_owners/${user.id}.jpg';
      await _sb.storage.from('profile-images').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );
      imageUrl = _sb.storage.from('profile-images').getPublicUrl(path);
    }

    final updateMap = <String, dynamic>{
      'name': name.trim(),
      'phone_number': phone.trim(),
      'address': address.trim(),
      'city': city.trim(),
      if (imageUrl != null) 'image_url': imageUrl,
    };

    if (newEmail != null && newEmail.trim().isNotEmpty) {
      final normalized = newEmail.trim().toLowerCase();

      final currentAuthEmail = (user.email ?? '').toLowerCase();
      if (normalized != currentAuthEmail) {
        final available = await isEmailAvailable(normalized);
        if (!available) {
          throw Exception('Email already in use. Please use a different email address.');
        }
        try {
          await _sb.auth.updateUser(UserAttributes(email: normalized));
        } catch (e) {
          throw Exception('Could not update auth email: $e');
        }
        updateMap['email'] = normalized;
      }
    }

    await _sb.from('pet_owners').update(updateMap).eq('user_id', user.id);

    return imageUrl;
  }
}
