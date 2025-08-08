import 'package:flutter/material.dart';
import 'package:scooby_app_new/models/service.dart';

class ServicesGrid extends StatelessWidget {
  const ServicesGrid({super.key});

  final List<ServiceItem> services = const [
    ServiceItem(
      icon: Icons.medical_services,
      title: 'Veterinarian',
      description: 'Expert medical care', route: '',
   //   route: AppRoutes.veterinarian,
    ),
    ServiceItem(
      icon: Icons.pets,
      title: 'Pet Sitter',
      description: 'Trusted pet care', route: '',
 //     route: AppRoutes.petSitter,
    ),
    ServiceItem(
      icon: Icons.content_cut,
      title: 'Pet Groomer',
      description: 'Professional grooming', route: '',
 //     route: AppRoutes.petGroomer,
    ),
    ServiceItem(
      icon: Icons.local_hospital,
      title: 'Emergency Care',
      description: '24/7 urgent care', route: '',
    //  route: AppRoutes.emergency,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, service.route),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A4C93),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    service.icon,
                    size: 30,
                    color: const Color(0xFF6A4C93),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  service.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  service.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AppRoutes {
}