import 'package:flutter/material.dart';
import 'package:scooby_app_new/models/service_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scooby_app_new/views/screens/service_provider_details_screen.dart';

class PetGroomerScreen extends StatelessWidget {
  const PetGroomerScreen({super.key});

  Future<List<Map<String, dynamic>>> fetchGroomers() async {
    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('service_providers')
        .select()
        .eq('providerRole', 'Pet Groomer');

    // response is List<dynamic> directly, no more PostgrestResponse wrapper
    // So no error property here, but if something went wrong, it'll throw

    if (response == null) {
      throw Exception('Failed to load groomers');
    }

    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Groomer Booking'),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchGroomers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No pet groomers found.'));
          }

          final groomers = snapshot.data!;

          return ListView.builder(
            itemCount: groomers.length,
            itemBuilder: (context, index) {
              final groomerData = groomers[index];

              return Card(
                margin: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 4,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  title: Text(
                    groomerData['name'] ?? 'No Name',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(groomerData['city'] ?? 'No City'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ServiceProviderDetailsScreen(
                              data: groomerData,
                              serviceProvider: ServiceProvider.fromMap(groomerData),
                            ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
