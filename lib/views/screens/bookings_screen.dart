// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> bookings = [];
  bool isLoading = true;
  String? ownerId;

  @override
  void initState() {
    super.initState();
    fetchOwnerIdAndBookings();
  }

  Future<void> fetchOwnerIdAndBookings() async {
    setState(() => isLoading = true);

    try {
      // Get current auth user
      final authUserId = supabase.auth.currentUser?.id;
      if (authUserId == null) {
        debugPrint('No logged-in user found.');
        setState(() => isLoading = false);
        return;
      }

      // Get ownerId from pet_owners table
      final ownerResponse = await supabase
          .from('pet_owners')
          .select('id')
          .eq('user_id', authUserId)
          .single();

      if (ownerResponse == null || ownerResponse['id'] == null) {
        debugPrint('No pet owner found for this user.');
        setState(() => isLoading = false);
        return;
      }

      ownerId = ownerResponse['id'] as String;
      debugPrint('OwnerId fetched: $ownerId');

      // Fetch bookings
      await fetchBookings();
    } catch (e) {
      debugPrint('Error fetching owner/bookings: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchBookings() async {
    if (ownerId == null) return;

    setState(() => isLoading = true);
    try {
      final data = await supabase
          .from('bookings')
          .select()
          .eq('owner_id', ownerId);

      final bookingList = List<Map<String, dynamic>>.from(data as List);

      debugPrint('Bookings fetched: ${bookingList.length}');

      setState(() {
        bookings = bookingList;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch bookings: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : bookings.isEmpty
              ? const Center(child: Text('No bookings found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.event),
                        title: Text(booking['owner_name'] ?? 'Booking'),
                        subtitle: Text(
                          'Date: ${booking['date'].toString().split('T')[0]} \n'
                          'Time: ${booking['time']} \n'
                          'Status: ${booking['status']}',
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
