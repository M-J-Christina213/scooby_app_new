import 'package:flutter/material.dart';
import 'package:scooby_app_new/controllers/service_provider_service.dart';
import 'package:scooby_app_new/models/service_provider.dart';
import 'package:scooby_app_new/views/screens/bookings_screen.dart';
import 'package:scooby_app_new/views/screens/my_pets_screen.dart';
import 'package:scooby_app_new/views/screens/profile_screen.dart';
import 'package:scooby_app_new/widgets/bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  final String userCity;

  const HomeScreen({
    super.key,
    required this.userId,
    required this.userCity,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ServiceProviderService _service = ServiceProviderService();

  int _selectedIndex = 0;
  String _selectedRole = 'Veterinarian';
  List<ServiceProvider> _nearbyProviders = [];
  List<ServiceProvider> _recommendedProviders = [];
  bool _loading = true;

  final List<Map<String, String>> _serviceTypes = const [
    {'title': 'Veterinarian', 'image': 'assets/images/vet.png'},
    {'title': 'Pet Groomer', 'image': 'assets/images/groomer.png'},
    {'title': 'Pet Sitter', 'image': 'assets/images/sitter.webp'},
  ];

  final List<String> _petTips = [
    'Make sure your pet drinks enough water.',
    'Regular grooming keeps your pet healthy.',
    'Daily walks help your pet stay active.',
    'Vaccinate your pets on time.',
    'Healthy diet leads to happy pets.',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final nearby = await _service.fetchServiceProvidersByCityAndRole(
        widget.userCity,
        _selectedRole,
      );
      final recommended = await _service.fetchRecommendedServiceProviders(
        widget.userId,
      );

      setState(() {
        _nearbyProviders = nearby;
        _recommendedProviders = recommended;
      });
    } catch (e) {
      debugPrint('Error loading providers: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onRoleSelected(String role) {
    if (_selectedRole != role) {
      setState(() => _selectedRole = role);
      _loadData();
    }
  }

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);

    setState(() {
    _selectedIndex = index;
  });

  switch (index) {
    case 0:
      // Already on HomeScreen, no action needed
      break;
    case 1:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MyPetsScreen(userId: widget.userId),
        ),
      );
      break;
    case 2:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingsScreen(),
        ),
      );
      break;
  case 3:
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(),
      ),
    );
    break;
}
}

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF842EAC);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Welcome to Scooby',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Banner
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/banner1bg.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Caring for your pets, always!',
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Service Types
                  _buildSectionTitle('Service Types', primaryColor),
                  const SizedBox(height: 12),
                  _buildServiceTypeList(primaryColor),
                  const SizedBox(height: 24),

                  // Nearby
                  _buildSectionTitle('Nearby $_selectedRole"s', primaryColor),
                  const SizedBox(height: 12),
                  _buildProviderList(_nearbyProviders, 'No nearby providers found.'),

                  const SizedBox(height: 24),

                  // Recommended
                  _buildSectionTitle('Recommended for You', primaryColor),
                  const SizedBox(height: 12),
                  _buildProviderList(_recommendedProviders, 'No recommendations available.'),

                  const SizedBox(height: 24),

                  // Pet Care Tips
                  _buildPetCareTips(primaryColor),
                ],
              ),
            ),
      bottomNavigationBar: BottomNav(
        selectedIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
    );
  }

  Widget _buildServiceTypeList(Color primaryColor) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _serviceTypes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final service = _serviceTypes[index];
          final isSelected = service['title'] == _selectedRole;
          return GestureDetector(
            onTap: () => _onRoleSelected(service['title']!),
            child: Container(
              width: 140,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor.withAlpha(51) : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(service['image']!, height: 80),
                  const SizedBox(height: 12),
                  Text(
                    service['title']!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProviderList(List<ServiceProvider> providers, String emptyMessage) {
    return providers.isEmpty
        ? Text(emptyMessage)
        : SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: providers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final provider = providers[index];
                return _ServiceProviderCard(
                  provider: provider,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ServiceDetailScreen(serviceProvider: provider),
                      ),
                    );
                  },
                );
              },
            ),
          );
  }

  Widget _buildPetCareTips(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Pet Care Tips', primaryColor),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _petTips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                return Container(
                  width: 250,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _petTips[index],
                    style: const TextStyle(fontSize: 16),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceProviderCard extends StatelessWidget {
  final ServiceProvider provider;
  final VoidCallback onTap;

  const _ServiceProviderCard({
    required this.provider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            provider.profileImageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      provider.profileImageUrl,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.pets, size: 60, color: Colors.white),
                  ),
            const SizedBox(height: 8),
            Text(
              provider.clinicOrSalonName.isNotEmpty
                  ? provider.clinicOrSalonName
                  : provider.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              provider.serviceDescription,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('⭐ ${provider.rate}', style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.message, color: Colors.purple),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceDetailScreen extends StatelessWidget {
  final ServiceProvider serviceProvider;

  const ServiceDetailScreen({super.key, required this.serviceProvider});

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF842EAC);

    return Scaffold(
      appBar: AppBar(
        title: Text(serviceProvider.clinicOrSalonName.isNotEmpty
            ? serviceProvider.clinicOrSalonName
            : serviceProvider.name),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (serviceProvider.profileImageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  serviceProvider.profileImageUrl,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 12),
            Text(serviceProvider.aboutClinicSalon, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Text('Experience: ${serviceProvider.experience} years'),
            const SizedBox(height: 8),
            Text('Description: ${serviceProvider.serviceDescription}'),
            const SizedBox(height: 8),
            Text('Pricing: ${serviceProvider.pricingDetails.isNotEmpty ? serviceProvider.pricingDetails : "Not specified"}'),
            const SizedBox(height: 8),
            Text('Consultation Fee: ${serviceProvider.consultationFee.isNotEmpty ? serviceProvider.consultationFee : "Not specified"}'),
            const SizedBox(height: 8),
            Text('Rating: ⭐ ${serviceProvider.rate}'),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.calendar_today),
              label: const Text('Book an Appointment'),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
