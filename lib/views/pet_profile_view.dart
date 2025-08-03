import 'package:flutter/material.dart';
import 'package:scooby_app_new/models/pet.dart';
import 'package:scooby_app_new/views/add_pet_screen.dart';

class PetProfileScreen extends StatelessWidget {
  final Pet pet;
  const PetProfileScreen({required this.pet, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${pet.name}\'s Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => PetFormScreen(pet: pet),
            )),
          ),
        ],
      ),
      body: ListView(
        children: [
          Image.network(pet.imageUrl ?? '', height: 200, width: double.infinity, fit: BoxFit.cover),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Colors.purple, Colors.deepPurple]),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pet.name, style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
                Text('${pet.breed} • ${pet.gender}', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _infoRow("Age", "${pet.age} yrs"),
                _infoRow("Weight", "${pet.weight} kg"),
                _infoRow("Height", "${pet.height} cm"),
                _infoRow("Color", pet.color ?? ''),
                const SizedBox(height: 12),
                _infoRow("Favourite Thing", pet.description ?? 'Not added'),
                const Divider(),
                _infoRow("Medical Info", pet.medicalHistory ?? 'Not added'),
                _infoRow("Food", pet.foodPreference ?? 'Not added'),
                _infoRow("Mood", pet.mood ?? 'Unknown'),
                _infoRow("Health Status", pet.healthStatus ?? 'Unknown'),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Flexible(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
