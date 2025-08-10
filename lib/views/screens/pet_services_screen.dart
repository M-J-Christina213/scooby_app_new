import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scooby_app_new/controllers/service_provider_controller.dart';
import 'package:scooby_app_new/models/service_provider.dart';

class PetServicesScreen extends StatelessWidget {
  final String userCity;

  const PetServicesScreen({super.key, required this.userCity});

  static const List<Map<String, String>> serviceTypes = [
    {'title': 'Veterinarian', 'image': 'assets/images/vet.png'},
    {'title': 'Pet Groomer', 'image': 'assets/images/groomer.png'},
    {'title': 'Pet Sitter', 'image': 'assets/images/sitter.webp'},
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final controller = ServiceProviderController();
        controller.loadProviders(userCity);
        return controller;
      },
      child: Consumer<ServiceProviderController>(
        builder: (context, controller, _) {
          final primaryColor = const Color(0xFF842EAC);

          return controller.loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => controller.loadProviders(userCity),
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
                      Text(
                        'Service Types',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 180,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: serviceTypes.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            final service = serviceTypes[index];
                            final isSelected = service['title'] == controller.selectedRole;
                            return GestureDetector(
                              onTap: () => controller.changeRole(service['title']!, userCity),
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
                      ),
                      const SizedBox(height: 24),

                      // Providers List
                      Text(
                        'Nearby ${controller.selectedRole}s',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),

                      controller.providers.isEmpty
                          ? Text('No nearby providers found.')
                          : SizedBox(
                              height: 220,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: controller.providers.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 16),
                                itemBuilder: (context, index) {
                                  final provider = controller.providers[index];
                                  return _ServiceProviderCard(provider: provider);
                                },
                              ),
                            ),
                    ],
                  ),
                );
        },
      ),
    );
  }
}

class _ServiceProviderCard extends StatelessWidget {
  final ServiceProvider provider;

  const _ServiceProviderCard({required this.provider});

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: () {
        // Implement navigation to detailed screen if you want
      },
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
              provider.clinicOrSalonName.isNotEmpty ? provider.clinicOrSalonName : provider.name,
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
                Text(
                  '⭐ ${provider.rate}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.message, color: Colors.purple),
                  onPressed: () {
                    // Optional: open chat with provider
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
