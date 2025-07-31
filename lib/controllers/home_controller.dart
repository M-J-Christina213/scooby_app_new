import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeController {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Returns a Stream of the owner's name for reactive UI updates
  Stream<String> get ownerNameStream {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return Stream.value('Guest');
    }

    return _supabase
        .from('pet_owners')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .map((List<Map<String, dynamic>> data) {
      if (data.isEmpty) return 'User';
      final first = data.first;
      return first['name'] as String? ?? 'User';
    });
  }

  // One-time fetch of owner name (optional, keep if needed)
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

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

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
              await signOut();
              // Add navigation logic here if needed
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void fetchPetOwnerData() {
    // You can add any caching or initialization logic here if needed
  }
}
