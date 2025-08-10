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

class _MyPetsScreenState extends State<MyPetsScreen> with SingleTickerProviderStateMixin {
  final PetService _petService = PetService();
  late Future<List<Pet>> _petsFuture;
  final Color _primaryColor = const Color(0xFF842EAC);

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadPets();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              itemCount: pets.length,
              itemBuilder: (context, index) {
                final pet = pets[index];
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: GestureDetector(
                    onTap: () => _goToPetDetails(pet),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withAlpha(40),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            child: pet.imageUrl != null
                                ? Image.network(
                                    pet.imageUrl!,
                                    width: double.infinity,
                                    height: 220,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: double.infinity,
                                    height: 220,
                                    color: _primaryColor.withAlpha(50),
                                    child: Icon(
                                      Icons.pets,
                                      size: 100,
                                      color: _primaryColor,
                                    ),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            child: Column(
                              children: [
                                Text(
                                  pet.name,
                                  style: TextStyle(
                                    color: _primaryColor,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${pet.breed ?? 'Unknown Breed'} • Age: ${pet.age ?? 'N/A'}',
                                  style: TextStyle(
                                    color: _primaryColor.withAlpha(180),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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
      backgroundColor: _primaryColor.withAlpha(20),
    );
  }
}
