import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeController {
  final SupabaseClient _supabase = Supabase.instance.client;


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

    return response.data['name'] ?? 'User';
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
              // You can add redirection if needed
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void fetchPetOwnerData() {
  
  }
}
