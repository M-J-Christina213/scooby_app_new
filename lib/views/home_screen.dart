import 'package:flutter/material.dart';
import 'package:scooby_app_new/controllers/home_controller.dart';
import 'package:scooby_app_new/models/pet.dart';
import 'package:scooby_app_new/views/adoption_screen.dart';
import 'package:scooby_app_new/views/bottom_nav.dart';
import 'package:scooby_app_new/views/community_screen.dart';
import 'package:scooby_app_new/views/pet_owner_profile_screen.dart';
import 'package:scooby_app_new/views/services_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController _controller = HomeController();
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    // The main home screen content (pets list)
    PetsScreen(),
    const ServicesScreen(),
    const AdoptionScreen(),
    const CommunityScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _controller.fetchPetOwnerData();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scooby App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PetOwnerProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNav(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class PetsScreen extends StatelessWidget {
  final HomeController _controller = HomeController();

  PetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text("Your Pets", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        StreamBuilder<List<Pet>>(
          stream: _controller.petListStream,
          builder: (context, snapshot) {
            final pets = snapshot.data ?? [];
            if (pets.isEmpty) {
              return Center(
                child: ElevatedButton(
                  onPressed: () => _controller.goToAddPet(context),
                  child: const Text("Add Your First Pet"),
                ),
              );
            }

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: pets.map((pet) {
                return GestureDetector(
                  onTap: () => _controller.goToViewPetProfile(context, pet),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(pet.imageUrl ?? ''),
                      ),
                      const SizedBox(height: 6),
                      Text(pet.name,
                          style: const TextStyle(fontWeight: FontWeight.bold))
                    ],
                  ),
                );
              }).toList()
                ..add(
                  GestureDetector(
                    onTap: () => _controller.goToAddPet(context),
                    child: Column(
                      children: const [
                        CircleAvatar(
                          radius: 40,
                          child: Icon(Icons.add),
                        ),
                        SizedBox(height: 6),
                        Text("Add Pet"),
                      ],
                    ),
                  ),
                ),
            );
          },
        ),
      ],
    );
  }
}
