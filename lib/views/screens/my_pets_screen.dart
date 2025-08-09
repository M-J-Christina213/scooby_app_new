import 'package:flutter/material.dart';
import 'package:scooby_app_new/controllers/pet_service.dart';
import 'package:scooby_app_new/models/pet.dart';
import 'add_pet_screen.dart';
import 'pet_detail_screen.dart';

class MyPetsScreen extends StatefulWidget {
  final String userId;
  const MyPetsScreen({required this.userId, super.key});

  @override
  State<MyPetsScreen> createState() => _MyPetsScreenState();
}

class _MyPetsScreenState extends State<MyPetsScreen> {
  final PetService _petService = PetService();
  late Future<List<Pet>> _petsFuture;

  final Color _primaryColor = const Color(0xFF842EAC);

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  void _loadPets() {
    _petsFuture = _petService.fetchPetsForUser(widget.userId);
  }

  Future<void> _refreshPets() async {
    setState(() {
      _loadPets();
    });
  }

  void _goToAddPet() async {
    final added = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPetScreen(userId: widget.userId),
      ),
    );

    if (added == true) {
      _refreshPets();
    }
  }

  void _goToPetDetails(Pet pet) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PetDetailScreen(
          pet: pet,
          userId: widget.userId,
        ),
      ),
    );

    if (updated == true) {
      _refreshPets();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pets'),
        backgroundColor: _primaryColor,
        centerTitle: true,
      ),
      body: FutureBuilder<List<Pet>>(
        future: _petsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading pets: ${snapshot.error}'));
          }

          final pets = snapshot.data ?? [];

          if (pets.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pets, size: 80, color: _primaryColor),
                    const SizedBox(height: 20),
                    const Text(
                      'You have no pets yet.\nTap the + button below to add your first pet!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshPets,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: pets.length,
              itemBuilder: (context, index) {
                final pet = pets[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      backgroundImage: pet.imageUrl != null ? NetworkImage(pet.imageUrl!) : null,
                      child: pet.imageUrl == null ? Icon(Icons.pets, color: _primaryColor) : null,
                    ),
                    title: Text(pet.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${pet.type} • Age: ${pet.age ?? 'N/A'}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _goToPetDetails(pet),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToAddPet,
        backgroundColor: _primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}
