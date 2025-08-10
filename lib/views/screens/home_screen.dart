import 'package:flutter/material.dart';
import 'package:scooby_app_new/controllers/service_provider_service.dart';
import 'package:scooby_app_new/models/service_provider.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  final String userCity;

  const HomeScreen({super.key, required this.userId, required this.userCity});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ServiceProviderService _service = ServiceProviderService();

  String _selectedRole = 'Veterinarian';
  List<ServiceProvider> _nearbyProviders = [];
  List<ServiceProvider> _recommendedProviders = [];
  bool _loading = true;

  final List<Map<String, String>> _serviceTypes = const [
    {
      'title': 'Veterinarian',
      'description': 'Trusted vets for checkups & emergencies.',
      'image': 'assets/images/vet.png',
    },
    {
      'title': 'Pet Groomer',
      'description': 'Professional grooming at your convenience.',
      'image': 'assets/images/groomer.png',
    },
    {
      'title': 'Pet Sitter',
      'description': 'Reliable sitters while you’re away.',
      'image': 'assets/images/sitter.webp',
    },
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
    setState(() {
      _loading = true;
    });

    try {
      final nearby = await _service.fetchServiceProvidersByCityAndRole(widget.userCity, _selectedRole);
      final recommended = await _service.fetchRecommendedServiceProviders(widget.userId);

      setState(() {
        _nearbyProviders = nearby;
        _recommendedProviders = recommended;
      });
    } catch (e) {
      debugPrint('Error loading providers: $e');
    }

    setState(() {
      _loading = false;
    });
  }

  void _onRoleSelected(String role) {
    setState(() {
      _selectedRole = role;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF842EAC);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Scooby', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  // Top Banner
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/pet_banner.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.black.withAlpha(120),
                      ),
                      child: const Text(
                        'Caring for your pets, always!',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Service Types horizontal scroll
                  Text('Service Types', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor)),
                  const SizedBox(height: 12),
                  SizedBox(
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
                              border: Border.all(color: isSelected ? primaryColor : Colors.transparent, width: 2),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(color: primaryColor.withAlpha(77), blurRadius: 5, offset: const Offset(0, 3))
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(service['image']!, height: 70),
                                const SizedBox(height: 12),
                                Text(service['title']!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
                                const SizedBox(height: 6),
                                Text(service['description']!, style: const TextStyle(fontSize: 12, color: Colors.black54), textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Nearby Services Section
                  Text('Nearby ${_selectedRole}s', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
                  const SizedBox(height: 12),
                  _nearbyProviders.isEmpty
                      ? const Text('No nearby providers found.')
                      : SizedBox(
                          height: 220,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _nearbyProviders.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 16),
                            itemBuilder: (context, index) {
                              final provider = _nearbyProviders[index];
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
                        ),

                  const SizedBox(height: 24),

                  // Recommended Services Section
                  Text('Recommended for You', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
                  const SizedBox(height: 12),
                  _recommendedProviders.isEmpty
                      ? const Text('No recommendations available.')
                      : SizedBox(
                          height: 220,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _recommendedProviders.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 16),
                            itemBuilder: (context, index) {
                              final provider = _recommendedProviders[index];
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
                        ),

                  const SizedBox(height: 24),

                  // Pet Care Tips
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pet Care Tips', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
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
                                  boxShadow: [
                                    BoxShadow(color: Colors.grey.shade300, blurRadius: 6, offset: const Offset(0, 3)),
                                  ],
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
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

class _ServiceProviderCard extends StatelessWidget {
  final ServiceProvider provider;
  final VoidCallback onTap;

  const _ServiceProviderCard({required this.provider, required this.onTap});

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
          boxShadow: [
            BoxShadow(color: Colors.grey.shade300, blurRadius: 6, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            provider.profileImageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(provider.profileImageUrl, height: 100, width: double.infinity, fit: BoxFit.cover),
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
            Text(provider.clinicOrSalonName.isNotEmpty ? provider.clinicOrSalonName : provider.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(provider.serviceDescription, maxLines: 2, overflow: TextOverflow.ellipsis),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('⭐ ${provider.rate}', style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.message, color: Colors.purple),
                  onPressed: () {
                    
                  },
                ),
              ],
            )
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
        title: Text(serviceProvider.clinicOrSalonName.isNotEmpty ? serviceProvider.clinicOrSalonName : serviceProvider.name),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (serviceProvider.profileImageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(serviceProvider.profileImageUrl, height: 200, fit: BoxFit.cover),
              ),
            const SizedBox(height: 12),
            Text(
              serviceProvider.aboutClinicSalon,
              style: const TextStyle(fontSize: 16),
            ),
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
              onPressed: () {
                
              },
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
