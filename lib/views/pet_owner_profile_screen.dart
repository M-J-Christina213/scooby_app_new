import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scooby_app_new/models/pet_owner_model.dart';

class PetOwnerProfileScreen extends StatelessWidget {
  const PetOwnerProfileScreen({super.key});

  Future<PetOwner?> _fetchPetOwner() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    final response = await Supabase.instance.client
        .from('pet_owners')
        .select()
        .eq('id', user.id)
        .single();

    if (response != null && response.isNotEmpty) {
      return PetOwner.fromMap(response);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: const Color(0xFF6A0DAD),
      ),
      body: FutureBuilder<PetOwner?>(
        future: _fetchPetOwner(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;
          if (user == null) {
            return const Center(child: Text("No user data found."));
          }

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: ListView(
              children: [
                const CircleAvatar(
                  radius: 150,
                  backgroundImage: AssetImage('assets/images/profile.jpeg'),
                ),
                const SizedBox(height: 20),
                Text("Name: ${user.name}", style: const TextStyle(fontSize: 18)),
                Text("Email: ${user.email}", style: const TextStyle(fontSize: 18)),
                Text("Phone: ${user.phone}", style: const TextStyle(fontSize: 18)),
                Text("City: ${user.city}", style: const TextStyle(fontSize: 18)),
                Text("Address: ${user.address}", style: const TextStyle(fontSize: 18)),
              ],
            ),
          );
        },
      ),
    );
  }
}
