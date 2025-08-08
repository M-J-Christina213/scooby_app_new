import 'package:flutter/material.dart';
import 'package:scooby_app_new/models/service_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> nearbyServices = [];
  List<dynamic> recommendedServices = [];
  List<dynamic> topRatedServices = [];

  @override
  void initState() {
    super.initState();
    fetchServices();
  }

  Future<void> fetchServices() async {
    final nearby = await supabase.from('services').select().limit(5);
    final recommended = await supabase.from('services').select().limit(5);
    final topRated = await supabase.from('services').select().limit(5);

    setState(() {
      nearbyServices = nearby;
      recommendedServices = recommended;
      topRatedServices = topRated;
    });
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login'); 
    }
  }

  Future<void> _confirmSignOut() async {
  final bool? shouldSignOut = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Confirm Sign Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF842EAC),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log Out'),
          ),
        ],
      );
    },
  );

  if (shouldSignOut == true) {
    await _signOut();
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2FA),
      appBar: AppBar(
        title: const Text(
          "PetPal",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF842EAC), // updated purple
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sign Out',
            onPressed: _confirmSignOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Explore Our Services
            const Text(
              "Explore Our Services",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildServiceIcon(Icons.local_hospital, "Veterinarian"),
                _buildServiceIcon(Icons.content_cut, "Pet Groomer"),
                _buildServiceIcon(Icons.pets, "Pet Sitter"),
              ],
            ),
            const SizedBox(height: 20),

            // Nearby Services
            _buildSectionTitle("Nearby Services"),
            _buildHorizontalList(nearbyServices),

            // Recommended for You
            _buildSectionTitle("Recommended for You"),
            _buildHorizontalList(recommendedServices),

            // Top Rated
            _buildSectionTitle("Top Rated"),
            _buildHorizontalList(topRatedServices),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceIcon(IconData icon, String label) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE1BEE7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 30, color: const Color(0xFF6A1B9A)),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildHorizontalList(List<dynamic> services) {
    if (services.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return ServiceCard(
            name: service['name'] ?? 'Unknown',
            category: service['category'] ?? '',
            imageUrl: service['image_url'] ?? '',
            provider: ServiceProvider.fromMap(service),
            onTap: () {},
          );
        },
      ),
    );
  }
}

// Service Card Widget
class ServiceCard extends StatelessWidget {
  final String name;
  final String category;
  final String imageUrl;
  final ServiceProvider provider;
  final VoidCallback onTap;

  const ServiceCard({
    super.key,
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.provider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 6,
              spreadRadius: 2,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl,
                      height: 100, width: double.infinity, fit: BoxFit.cover)
                  : Container(
                      height: 100,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, size: 50),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(category,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
