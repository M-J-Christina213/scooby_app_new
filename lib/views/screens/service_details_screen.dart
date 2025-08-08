import 'package:flutter/material.dart';
import 'package:scooby_app_new/models/service_provider.dart';

class ServiceDetailsScreen extends StatelessWidget {
  final ServiceProvider serviceProvider;

  const ServiceDetailsScreen({super.key, required this.serviceProvider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(serviceProvider.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (serviceProvider.profileImageUrl != null)
              Image.network(serviceProvider.profileImageUrl!),
            const SizedBox(height: 12),
            Text(
              serviceProvider.clinicOrSalonName ?? '',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(serviceProvider.aboutClinicSalon ?? ''),
          ],
        ),
      ),
    );
  }
}

extension on ServiceProvider {
  get profileImageUrl => null;
  
  get aboutClinicSalon => null;
}
