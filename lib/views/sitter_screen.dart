import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scooby_app_new/views/service_provider_details_screen.dart';

class PetSitterScreen extends StatelessWidget {
  const PetSitterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Sitter Booking'),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('service_providers')
            .where('providerRole', isEqualTo: 'Pet Sitter')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No pet sitters found.'));
          }

          final sitters = snapshot.data!.docs;

          return ListView.builder(
            itemCount: sitters.length,
            itemBuilder: (context, index) {
              final sitterData = sitters[index].data() as Map<String, dynamic>;

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
                        builder: (_) => ServiceProviderDetailsScreen(data: sitterData),
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
