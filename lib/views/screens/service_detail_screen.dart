import 'package:flutter/material.dart';
import 'package:scooby_app_new/models/service_provider.dart';
import 'package:scooby_app_new/views/screens/booking_screen.dart';

class ServiceDetailScreen extends StatefulWidget {
  final ServiceProvider serviceProvider;

  const ServiceDetailScreen({super.key, required this.serviceProvider});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  final Color primaryColor = const Color(0xFF842EAC);
  int _currentGalleryIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sp = widget.serviceProvider;

    return Scaffold(
      appBar: AppBar(
        title: Text(sp.clinicOrSalonName.isNotEmpty ? sp.clinicOrSalonName : sp.name),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 8, spreadRadius: 2)
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(_createRoute());
            },
            icon: const Icon(Icons.calendar_today),
            label: const Text('Book Appointment', style: TextStyle(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: primaryColor,
            expandedHeight: 320,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: sp.profileImageUrl.isNotEmpty
                  ? Image.network(sp.profileImageUrl, fit: BoxFit.cover)
                  : Image.asset('assets/images/default_user.png', fit: BoxFit.cover),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Name & City
                Text(
                  sp.clinicOrSalonName.isNotEmpty ? sp.clinicOrSalonName : sp.name,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.grey, size: 18),
                    const SizedBox(width: 4),
                    Text(sp.city, style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                  ],
                ),
                const SizedBox(height: 12),

                _buildRatingRow(sp.rate),
                const SizedBox(height: 20),

                // Gallery Section
                if (sp.galleryImages.isNotEmpty) _buildGallery(sp.galleryImages),
                if (sp.galleryImages.isNotEmpty) const SizedBox(height: 20),

                // Details Card
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  shadowColor: primaryColor.withAlpha((0.2 * 255).round()),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: _buildDynamicDetails(sp),
                  ),
                ),
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGallery(List<String> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gallery',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() => _currentGalleryIndex = index);
            },
            itemBuilder: (context, index) {
              final imgUrl = images[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imgUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(images.length, (index) {
            bool isActive = index == _currentGalleryIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 16 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? primaryColor : primaryColor.withAlpha((0.3 * 255).round()),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Route _createRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          BookingScreen(serviceProvider: widget.serviceProvider),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // Slide from right
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  Widget _buildRatingRow(String rate) {
    double rating = 4.5; // default/fake rating or parse from rate
    try {
      rating = double.parse(rate);
    } catch (_) {}

    List<Widget> stars = [];
    for (int i = 1; i <= 5; i++) {
      stars.add(Icon(
        i <= rating ? Icons.star : Icons.star_border,
        color: Colors.amber,
        size: 24,
      ));
    }

    return Row(
      children: [
        ...stars,
        const SizedBox(width: 8),
        Text(
          rate.isNotEmpty ? rate : 'N/A',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDynamicDetails(ServiceProvider sp) {
    const contentStyle = TextStyle(fontSize: 15, color: Colors.black87);

    switch (sp.role) {
      case 'Veterinarian':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('About the Clinic'),
            Text(sp.aboutClinicSalon.isNotEmpty ? sp.aboutClinicSalon : 'No info available', style: contentStyle),
            const SizedBox(height: 16),

            _sectionTitle('Clinic Address'),
            Text(sp.clinicOrSalonAddress.isNotEmpty ? sp.clinicOrSalonAddress : 'No info available', style: contentStyle),
            const SizedBox(height: 16),

            _sectionTitle('Experience'),
            Text('${sp.experience} years', style: contentStyle),
            const SizedBox(height: 16),

            _sectionTitle('Service Description'),
            Text(sp.serviceDescription.isNotEmpty ? sp.serviceDescription : 'No info available', style: contentStyle),
            const SizedBox(height: 16),

            _sectionTitle('Consultation Fee'),
            Text(sp.consultationFee.isNotEmpty ? sp.consultationFee : 'Not specified', style: contentStyle),
            const SizedBox(height: 16),

            _sectionTitle('Notes'),
            Text(sp.notes.isNotEmpty ? sp.notes : 'No notes', style: contentStyle),
          ],
        );

      case 'Pet Groomer':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('About the Salon'),
            Text(sp.aboutClinicSalon.isNotEmpty ? sp.aboutClinicSalon : 'No info available', style: contentStyle),
            const SizedBox(height: 16),

            _sectionTitle('Salon Address'),
            Text(sp.clinicOrSalonAddress.isNotEmpty ? sp.clinicOrSalonAddress : 'No info available', style: contentStyle),
            const SizedBox(height: 16),

            _sectionTitle('Experience'),
            Text('${sp.experience} years', style: contentStyle),
            const SizedBox(height: 16),

            _sectionTitle('Service Description'),
            Text(sp.serviceDescription.isNotEmpty ? sp.serviceDescription : 'No info available', style: contentStyle),
            const SizedBox(height: 16),

            _sectionTitle('Pricing Details'),
            Text(sp.pricingDetails.isNotEmpty ? sp.pricingDetails : 'Not specified', style: contentStyle),
            const SizedBox(height: 16),

            _sectionTitle('Grooming Services'),
            _chipList(sp.groomingServices),
            const SizedBox(height: 16),

            _sectionTitle('Notes'),
            Text(sp.notes.isNotEmpty ? sp.notes : 'No notes', style: contentStyle),
          ],
        );

      case 'Pet Sitter':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Available Days & Times'),
            Text(sp.availableTimes.isNotEmpty ? sp.availableTimes : 'Not specified', style: contentStyle),
            const SizedBox(height: 16),

            _sectionTitle('Comfortable With'),
            _chipList(sp.comfortableWith),
            const SizedBox(height: 16),

            _sectionTitle('Service Description'),
            Text(sp.serviceDescription.isNotEmpty ? sp.serviceDescription : 'No info available', style: contentStyle),
            const SizedBox(height: 16),

            _sectionTitle('Special Notes'),
            Text(sp.notes.isNotEmpty ? sp.notes : 'No notes', style: contentStyle),
            const SizedBox(height: 16),

            _sectionTitle('Experience'),
            Text('${sp.experience} years', style: contentStyle),
            const SizedBox(height: 16),

            _sectionTitle('Hourly / Daily Rate'),
            Text(sp.rate.isNotEmpty ? sp.rate : 'Not specified', style: contentStyle),
          ],
        );

      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Description'),
            Text(sp.serviceDescription.isNotEmpty ? sp.serviceDescription : 'No info available', style: contentStyle),
          ],
        );
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }

  Widget _chipList(List<String> items) {
    if (items.isEmpty) {
      return const Text('Not specified');
    }
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: items
          .map((item) => Chip(
                label: Text(item),
                backgroundColor: const Color(0xFFEDE7F6),
                labelStyle: const TextStyle(color: Color(0xFF5E35B1)),
              ))
          .toList(),
    );
  }
}
