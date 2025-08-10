import 'package:supabase_flutter/supabase_flutter.dart';

class PetCareTipsService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<String>> fetchTips() async {
    final data = await _client
        .from('pet_care_tips')
        .select('tip')
        .order('created_at', ascending: false)
        .limit(10)
        .throwOnError()
        .then((response) => response.data as List<dynamic>);

    return data.map((e) => e['tip'] as String).toList();
  }
}

extension on PostgrestTransformBuilder {
  throwOnError() {}
}
