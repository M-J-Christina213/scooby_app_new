import 'package:flutter/material.dart';
import 'package:scooby_app_new/views/add_pet_screen.dart';
import 'package:scooby_app_new/views/login_screen.dart';
import 'package:scooby_app_new/views/pet_profile_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scooby_app_new/models/pet.dart';

class HomeController {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Stream for pet owner name
  Stream<String> get ownerNameStream {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return Stream.value('Guest');
    }

    return _supabase
        .from('pet_owners')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .map((data) {
      if (data.isEmpty) return 'User';
      return data.first['name'] as String? ?? 'User';
    });
  }

  // Stream for owner profile image
  Stream<String?> get ownerImageStream {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return _supabase
        .from('pet_owners')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .map((data) {
      if (data.isEmpty) return null;
      return data.first['image_url'] as String?;
    });
  }

  // One-time fetch of name
  Future<String> fetchOwnerName() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 'Guest';

    final response = await _supabase
        .from('pet_owners')
        .select('name')
        .eq('id', user.id)
        .single();

    if (response.error != null) {
      debugPrint('Error fetching name: ${response.error!.message}');
      return 'User';
    }

    return response.data?['name'] ?? 'User';
  }

  // One-time fetch of profile image
  Future<String?> fetchOwnerImage() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('pet_owners')
        .select('image_url')
        .eq('id', user.id)
        .single();

    if (response.error != null) {
      debugPrint('Error fetching image: ${response.error!.message}');
      return null;
    }

    return response.data?['image_url'];
  }

  /// Sign out and navigate to login screen
  Future<void> signOut(BuildContext context) async {
    await _supabase.auth.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  /// Shows logout confirmation dialog
  void showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await signOut(context);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  // --- PETS RELATED ---

  /// Stream of pets for the current logged-in user
  Stream<List<Pet>> get petListStream {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    // Listen to changes in 'pets' table for current user
    return _supabase
        .from('pets')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .map((List<Map<String, dynamic>> data) {
      return data.map((json) => Pet.fromJson(json)).toList();
    });
  }

  /// Navigate to add pet screen
  void goToAddPet(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PetFormScreen()),
    );
  }

  /// Navigate to pet profile view screen
  void goToViewPetProfile(BuildContext context, Pet pet) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PetProfileScreen(pet: pet)),
    );
  }

  /// Placeholder for any init logic
  void fetchPetOwnerData() {
    // Can add caching or pre-fetch logic here if needed
  }
}
