import 'package:flutter/material.dart';
import 'package:scooby_app_new/models/service_provider.dart';
import 'package:scooby_app_new/widgets/service_provider.dart';
import 'package:scooby_app_new/views/screens/service_detail_screen.dart';

class NearbyServicesScreen extends StatelessWidget {
  final List<ServiceProvider> providers;
  final String role;

  const NearbyServicesScreen({
    super.key,
    required this.providers,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF842EAC);

    return Scaffold(
      appBar: AppBar(
        title: Text("All Nearby $role's"),
        backgroundColor: purple,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: providers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final provider = providers[index];
          return ServiceProviderCard(
            provider: provider,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ServiceDetailScreen(
                    serviceProvider: provider,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
