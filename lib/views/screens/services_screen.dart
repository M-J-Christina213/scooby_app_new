import 'package:flutter/material.dart';
import 'vet_screen.dart';
import 'groomer_screen.dart';
import 'sitter_screen.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose a Service')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ServiceCard(
              title: 'Veterinarians',
              description: 'Book trusted vets for checkups & emergencies.',
              imagePath: 'assets/images/vet.png',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VetScreen()),
              ),
            ),
            const SizedBox(height: 16),
            ServiceCard(
              title: 'Groomers',
              description: 'Get professional grooming at your convenience.',
              imagePath: 'assets/images/groomer.png',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PetGroomerScreen()),
              ),
            ),
            const SizedBox(height: 16),
            ServiceCard(
              title: 'Pet Sitters',
              description: 'Find reliable sitters while you’re away.',
              imagePath: 'assets/images/sitter.webp',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PetSitterScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;
  final VoidCallback onTap;

  const ServiceCard({
    super.key,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110, // fixed height for uniform cards
      child: Card(
        elevation: 6,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Text section
                Expanded(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center, // center vertically
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        maxLines: 2, // restrict lines for uniform height
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Image section
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    imagePath,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
