import 'package:flutter/foundation.dart';
import 'package:scooby_app_new/controllers/service_provider_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_provider.dart';

class ServiceProviderController extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  final ServiceProviderService _service = ServiceProviderService(); // instantiate your service here

  List<ServiceProvider> providers = [];
  bool loading = false;
  String selectedRole = 'Veterinarian';

  Future<void> loadProviders(String city) async {
    loading = true;
    notifyListeners();

    try {
      // Use _service to fetch
      providers = await _service.fetchServiceProvidersByCityAndRole(city, selectedRole);
    } catch (e) {
      debugPrint('Error loading providers: $e');
      providers = [];
    }

    loading = false;
    notifyListeners();
  }

  void changeRole(String role, String city) {
    if (role != selectedRole) {
      selectedRole = role;
      loadProviders(city);
    }
  }

  Future<String> fetchProviderName() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 'Guest';

    final response = await _supabase
        .from('service_providers')
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
