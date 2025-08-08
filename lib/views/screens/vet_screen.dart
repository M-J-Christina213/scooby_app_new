import 'package:flutter/material.dart';
import 'package:scooby_app_new/models/service_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scooby_app_new/views/screens/service_provider_details_screen.dart';

class VetScreen extends StatefulWidget {
  const VetScreen({super.key});

  @override
  State<VetScreen> createState() => _VetScreenState();
}

class _VetScreenState extends State<VetScreen> {
  late Future<List<Map<String, dynamic>>> _vetListFuture;

  @override
  void initState() {
    super.initState();
    _vetListFuture = _fetchApprovedVets();
  }

  Future<List<Map<String, dynamic>>> _fetchApprovedVets() async {
    final response = await Supabase.instance.client
        .from('service_providers')
        .select()
        .eq('providerRole', 'Veterinarian')
        .eq('status', 'approved');

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('Veterinarian Booking'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _vetListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final vets = snapshot.data ?? [];

          if (vets.isEmpty) {
            return const Center(child: Text('No approved veterinarians found.'));
          }

          return ListView.builder(
            itemCount: vets.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final vetData = vets[index];

              return Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.deepPurple[100],
                    child: const Icon(Icons.pets, color: Colors.white, size: 30),
                  ),
                  title: Text(
                    vetData['name'] ?? 'No Name',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(vetData['city'] ?? 'No City'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ServiceProviderDetailsScreen(
                          serviceProvider: ServiceProvider.fromMap(vetData),
                          data: {},
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
