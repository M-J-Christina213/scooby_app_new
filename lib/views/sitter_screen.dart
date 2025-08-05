import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scooby_app_new/views/service_provider_details_screen.dart';

class PetSitterScreen extends StatefulWidget {
  const PetSitterScreen({super.key});

  @override
  State<PetSitterScreen> createState() => _PetSitterScreenState();
}

class _PetSitterScreenState extends State<PetSitterScreen> {
  late Future<List<Map<String, dynamic>>> _sitterListFuture;

  @override
  void initState() {
    super.initState();
    _sitterListFuture = _fetchPetSitters();
  }

  Future<List<Map<String, dynamic>>> _fetchPetSitters() async {
    final response = await Supabase.instance.client
        .from('service_providers')
        .select()
        .eq('providerRole', 'Pet Sitter');

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Sitter Booking'),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _sitterListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final sitters = snapshot.data ?? [];

          if (sitters.isEmpty) {
            return const Center(child: Text('No pet sitters found.'));
          }

          return ListView.builder(
            itemCount: sitters.length,
            padding: const EdgeInsets.all(10),
            itemBuilder: (context, index) {
              final sitterData = sitters[index];

              return Card(
                margin: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 4,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  title: Text(
                    sitterData['name'] ?? 'No Name',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(sitterData['city'] ?? 'No City'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ServiceProviderDetailsScreen(data: sitterData),
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
