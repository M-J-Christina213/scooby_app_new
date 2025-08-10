import 'package:flutter/material.dart';
import 'package:scooby_app_new/models/service_provider.dart';

class ServiceProviderCard extends StatelessWidget {
  final ServiceProvider provider;
  final VoidCallback? onTap;

  const ServiceProviderCard({super.key, required this.provider, this.onTap});

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
            BoxShadow(color: purple, blurRadius: 8, spreadRadius: 1),
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
              provider.clinicOrSalonName.isNotEmpty ? provider.clinicOrSalonName : provider.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Experience: ${provider.experience} yrs',
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
            const SizedBox(height: 4),
            _buildStarRating(4.5), // fake rating fixed 4.5 stars, or you can randomize
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
