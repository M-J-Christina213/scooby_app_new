import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_provider.dart';

class ServiceProviderService {
  final SupabaseClient _client = Supabase.instance.client;

  // Get providers by city + role
  Future<List<ServiceProvider>> fetchServiceProvidersByCityAndRole(String city, String role) async {
    final response = await _client
        .from('service_providers')
        .select()
        .eq('city', city)
        .eq('role', role);
        

    if (response.error != null) {
      throw Exception('Error fetching providers: ${response.error!.message}');
    }

    final data = response.data as List<dynamic>;
    return data.map((e) => ServiceProvider.fromMap(e as Map<String, dynamic>)).toList();
  }

  // Get recommended providers for this user
  Future<List<ServiceProvider>> fetchRecommendedServiceProviders(String userId) async {
    final response = await _client
        .from('recommended_services')
        .select('service_providers(*)')
        .eq('user_id', userId);

    if (response.error != null) {
      throw Exception('Error fetching recommended providers: ${response.error!.message}');
    }

    final data = response.data as List<dynamic>;
    return data.map((item) => ServiceProvider.fromMap(item['service_providers'] as Map<String, dynamic>)).toList();
  }
}
