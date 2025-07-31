import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceProviderController {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> fetchProviderName() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 'Guest';

    final response = await _supabase
        .from('service_providers')
        .select('name')
        .eq('id', user.id)
        .single();

    if (response.error != null) {
      ('Error fetching name: ${response.error!.message}');
      return 'User';
    }

    return response.data['name'] ?? 'User';
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<Map<String, dynamic>?> getProviderProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('service_providers')
        .select()
        .eq('id', user.id)
        .single();

    return response.data;
  }
}
