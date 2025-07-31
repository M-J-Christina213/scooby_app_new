import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class ServiceProviderHomeScreen extends StatelessWidget {
  final String serviceProviderEmail;

  const ServiceProviderHomeScreen({super.key, required this.serviceProviderEmail});

  Future<List<Map<String, dynamic>>> _fetchBookings(String email) async {
    final response = await supabase
        .from('bookings')
        .select()
        .eq('serviceProviderEmail', email)
        .order('date', ascending: true);

    // Ensure it's cast to a List of Maps
    return (response as List).cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Bookings")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchBookings(serviceProviderEmail),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final bookings = snapshot.data ?? [];

          if (bookings.isEmpty) {
            return const Center(child: Text("No bookings found."));
          }

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return ListTile(
                title: Text("Booking ID: ${booking['id']}"),
                subtitle: Text("Date: ${booking['date']}"),
              );
            },
          );
        },
      ),
    );
  }
}
