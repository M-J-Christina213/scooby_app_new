import 'package:flutter/material.dart';

class PetServicesScreen extends StatefulWidget {
  const PetServicesScreen({super.key});

  @override
  State<PetServicesScreen> createState() => _PetServicesScreenState();
}

class _PetServicesScreenState extends State<PetServicesScreen> with SingleTickerProviderStateMixin {
  final Color primaryColor = const Color(0xFF842EAC);

  final List<Map<String, String>> serviceTypes = [
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

  // Simulated city for now
  String userCity = 'Colombo';

  // Stub nearby services data
  final List<Map<String, String>> nearbyServices = [
    {
      'name': 'City Vet Clinic',
      'type': 'Veterinarian',
      'address': '123 Main St, Colombo',
      'image': 'assets/images/vet_clinic.png',
      'rating': '4.8',
    },
    {
      'name': 'Happy Paws Grooming',
      'type': 'Pet Groomer',
      'address': '45 Groomer Lane, Colombo',
      'image': 'assets/images/groomer_shop.png',
      'rating': '4.5',
    },
  ];

  // Stub recommended services
  final List<Map<String, String>> recommendedServices = [
    {
      'name': 'Best Pet Sitter',
      'type': 'Pet Sitter',
      'address': '89 Sitter Ave, Colombo',
      'image': 'assets/images/pet_sitter.png',
      'rating': '4.9',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        
        await Future.delayed(const Duration(seconds: 1));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(
                  image: AssetImage('assets/images/pet_banner.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Color.fromRGBO(132, 46, 172, 0.6), // purple alpha
                    BlendMode.dstATop,
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Welcome to Scooby\nCaring for your pets!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Service Types horizontal scroll
            const Text(
              'Services',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: serviceTypes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final service = serviceTypes[index];
                  return GestureDetector(
                    onTap: () {
                      
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 140,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withAlpha(40),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withAlpha(60),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(service['image']!, height: 70),
                          const SizedBox(height: 12),
                          Text(
                            service['title']!,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                                fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            service['description']!,
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Nearby Services
            const Text(
              'Nearby Services in Colombo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...nearbyServices.map((service) {
              return _buildServiceCard(service);
            }),
            const SizedBox(height: 24),

            // Recommended Services
            const Text(
              'Recommended For You',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...recommendedServices.map((service) {
              return _buildServiceCard(service);
            }),
            const SizedBox(height: 24),

            // Bonus: Pet Care Tips Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withAlpha(80),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                '🐾 Tip: Regular vet visits keep your pets healthy and happy!',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(Map<String, String> service) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withAlpha(50),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            service['image']!,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          service['name']!,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          '${service['type']} • ${service['address']}',
          style: const TextStyle(color: Colors.black54),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.amber[600],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 16, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                service['rating'] ?? 'N/A',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        onTap: () {
          
        },
      ),
    );
  }
}
