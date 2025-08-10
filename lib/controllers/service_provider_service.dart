import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_provider.dart';

class ServiceProviderService {
  final SupabaseClient _client = Supabase.instance.client;

  // Get providers by city + role
  Future<List<ServiceProvider>> fetchServiceProvidersByCityAndRole(String city, String role) async {
    try {
      final data = await _client
          .from('service_providers')
          .select()
          .eq('city', city)
          .eq('role', role);

      return (data as List<dynamic>)
          .map((e) => ServiceProvider.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error fetching providers: $e');
    }
  }

  // Get recommended providers for this user
  Future<List<ServiceProvider>> fetchRecommendedServiceProviders(String userId) async {
    try {
      final data = await _client
          .from('recommended_services')
          .select('service_providers(*)')
          .eq('user_id', userId);

      return (data as List<dynamic>)
          .map((item) => ServiceProvider.fromMap(item['service_providers'] as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error fetching recommended providers: $e');
    }
  }
}
