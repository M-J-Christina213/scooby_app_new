import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_provider.dart';

class ServiceProviderService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<ServiceProvider>> fetchServiceProvidersByCityAndRole(String city, String role) async {
    final response = await _client
        .from('service_providers')
        .select()
        .eq('city', city)
        .eq('role', role)
        .order('rate', ascending: false)
        .throwOnError()  // Throws exception on error, no need to check error manually
        .execute();

    // response.data is the list of maps
    final data = response.data as List<dynamic>;
    return data.map((e) => ServiceProvider.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<List<ServiceProvider>> fetchRecommendedServiceProviders(String userId) async {
    final response = await _client
        .from('recommended_services')
        .select('service_providers(*)')
        .eq('user_id', userId)
        .throwOnError()
        .execute();

    final data = response.data as List<dynamic>;
    return data.map((item) => ServiceProvider.fromMap(item['service_providers'] as Map<String, dynamic>)).toList();
  }
}

extension on PostgrestTransformBuilder {
  throwOnError() {}
}

extension on PostgrestFilterBuilder {
  throwOnError() {}
}
