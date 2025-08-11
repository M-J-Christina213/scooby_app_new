// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:scooby_app_new/views/screens/login_screen.dart';
import 'package:scooby_app_new/views/screens/sample_recommended_providers.dart';
import 'package:scooby_app_new/views/screens/service_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scooby_app_new/controllers/service_provider_service.dart';
import 'package:scooby_app_new/models/service_provider.dart';
import 'package:scooby_app_new/views/screens/bookings_screen.dart';
import 'package:scooby_app_new/views/screens/my_pets_screen.dart';
import 'package:scooby_app_new/views/screens/profile_screen.dart';
import 'package:scooby_app_new/views/screens/nearby_services_screen.dart'; // You need to create this!
import 'package:scooby_app_new/widgets/bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  final String userCity;
  final String userId;

  const HomeScreen({
    super.key,
    required this.userCity,
    required this.userId,
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

  late String currentUserId;

  late List<Widget> _tabsWithoutHome;

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

    currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

    _tabsWithoutHome = [
      MyPetsScreen(userId: currentUserId),
      BookingsScreen(),
      ProfileScreen(),
    ];

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final nearby = await _service.fetchServiceProvidersByCityAndRole(
        widget.userCity,
        _selectedRole,
      );
      final recommended = sampleRecommendedProviders;

      

      setState(() {
        _nearbyProviders = nearby;
        _recommendedProviders = recommended;
      });
    } catch (e) {
      debugPrint('Error loading providers: $e');
      _nearbyProviders = [];
      _recommendedProviders = [];
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
  }

@override
Widget build(BuildContext context) {
  final primaryColor = const Color(0xFF842EAC);

  return Scaffold(
    appBar: AppBar(
      title: Text(
        _selectedIndex == 0
            ? 'Welcome to Scooby'
            : _selectedIndex == 1
                ? 'My Pets'
                : _selectedIndex == 2
                    ? 'Bookings'
                    : 'Profile',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: primaryColor,
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () => _confirmLogout(context),
          tooltip: 'Logout',
        ),
      ],
    ),
    body: _selectedIndex == 0 ? _buildHomeContent() : _tabsWithoutHome[_selectedIndex - 1],
    bottomNavigationBar: BottomNav(
      selectedIndex: _selectedIndex,
      onTap: _onNavTap,
    ),
  );
}

void _confirmLogout(BuildContext context) async {
  final bool? logout = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Do you confirm to logout?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Logout'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      );
    },
  );

  if (logout == true) {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
}

  Widget _buildHomeContent() {
    final primaryColor = const Color(0xFF842EAC);

    return _loading
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

                // Nearby Services with See All
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nearby $_selectedRole\'s',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryColor),
                    ),
                    if (_nearbyProviders.length > 4)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NearbyServicesScreen(
                                providers: _nearbyProviders,
                                role: _selectedRole,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'See All',
                          style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                _nearbyProviders.isEmpty
                    ? Text('No nearby providers found.')
                    : SizedBox(
                        height: 220,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _nearbyProviders.length > 4
                              ? 4
                              : _nearbyProviders.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            final provider = _nearbyProviders[index];
                            return ServiceProviderCard(
                              provider: provider,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ServiceDetailScreen(serviceProvider: provider),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),

                const SizedBox(height: 24),

                // Recommended
                _buildSectionTitle('Recommended for You', primaryColor),
                const SizedBox(height: 12),
                _recommendedProviders.isEmpty
                    ? Text('No recommendations available.')
                    : SizedBox(
                        height: 220,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _recommendedProviders.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            final provider = _recommendedProviders[index];
                            return ServiceProviderCard(
                              provider: provider,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ServiceDetailScreen(serviceProvider: provider),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),

                const SizedBox(height: 24),

                // Pet Care Tips
                _buildPetCareTips(primaryColor),
              ],
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
                color: isSelected
                    ? primaryColor.withAlpha(51)
                    : Colors.grey[200],
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

class ServiceProviderCard extends StatelessWidget {
  final ServiceProvider provider;
  final VoidCallback? onTap;

  const ServiceProviderCard({
    super.key,
    required this.provider,
    this.onTap,
  });

  Widget _buildStarRating(double rating) {
    int fullStars = rating.floor();
    bool halfStar = (rating - fullStars) >= 0.5;
    return Row(
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return const Icon(Icons.star, color: Colors.amber, size: 16);
        } else if (index == fullStars && halfStar) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 16);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 16);
        }
      }),
    );
  }

  String _getPricingInfo(ServiceProvider p) {
    switch (p.role.toLowerCase()) {
      case 'veterinarian':
        return 'Consultation: ${p.consultationFee.isNotEmpty ? p.consultationFee : "N/A"}';
      case 'pet groomer':
        return 'Price: ${p.pricingDetails.isNotEmpty ? p.pricingDetails : "N/A"}';
      case 'pet sitter':
        return 'Rate: ${p.pricingDetails.isNotEmpty ? p.pricingDetails : "N/A"}';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final purple = const Color(0xFF842EAC);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: purple.withOpacity(0.15), blurRadius: 8, spreadRadius: 1),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: provider.profileImageUrl.isNotEmpty
                  ? Image.network(
                      provider.profileImageUrl,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 100,
                      color: Colors.grey[300],
                      child: const Icon(Icons.pets, size: 60, color: Colors.white),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.clinicOrSalonName.isNotEmpty
                  ? provider.clinicOrSalonName
                  : provider.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Experience: ${provider.experience} yrs',
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
            const SizedBox(height: 4),
            _buildStarRating(4.5), // fixed fake rating
            const SizedBox(height: 6),
            Text(
              _getPricingInfo(provider),
              style: TextStyle(color: purple, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
