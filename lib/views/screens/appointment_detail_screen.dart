import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final String bookingId;
  final String providerEmail;

  const AppointmentDetailScreen({
    super.key,
    required this.bookingId,
    required this.providerEmail,
  });

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? booking;
  Map<String, dynamic>? pet;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchBooking();
  }

  Future<void> fetchBooking() async {
    setState(() => loading = true);
    try {
      final resp = await supabase
          .from('bookings')
          .select('id, owner_name, owner_phone, date, time, pets(*)')
          .eq('id', widget.bookingId)
          .maybeSingle();

      if (resp != null) {
        booking = Map<String, dynamic>.from(resp);
        if (booking!['pets'] != null && (booking!['pets'] as List).isNotEmpty) {
          pet = Map<String, dynamic>.from(booking!['pets'][0]);
        }
      }
    } catch (e) {
      debugPrint('Error fetching booking: $e');
    }
    setState(() => loading = false);
  }

  Future<void> updateBookingStatus(String status) async {
    await supabase.from('bookings').update({'status': status}).eq('id', widget.bookingId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking ${status == 'accepted' ? 'accepted' : 'declined'} successfully'),
        backgroundColor: status == 'accepted' ? Colors.green : Colors.red,
      ),
    );
    Navigator.pop(context, true); // return true to refresh the list
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: Colors.deepPurple,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : booking == null
              ? const Center(child: Text('Booking not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Owner Info
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking!['owner_name'] ?? '',
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.phone, color: Colors.deepPurple),
                                  const SizedBox(width: 8),
                                  Text(booking!['owner_phone'] ?? ''),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: Colors.deepPurple),
                                  const SizedBox(width: 8),
                                  Text(booking!['date'] != null
                                      ? DateFormat.yMMMd().format(DateTime.parse(booking!['date']))
                                      : ''),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, color: Colors.deepPurple),
                                  const SizedBox(width: 8),
                                  Text(booking!['time'] ?? ''),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Pet Info
                      if (pet != null)
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pet!['name'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                                ),
                                const SizedBox(height: 8),
                                Text('Type: ${pet!['type'] ?? '-'}'),
                                Text('Breed: ${pet!['breed'] ?? '-'}'),
                                Text('Age: ${pet!['age'] ?? '-'}'),
                                Text('Gender: ${pet!['gender'] ?? '-'}'),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Accept / Decline Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () => updateBookingStatus('accepted'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            ),
                            child: const Text('Accept'),
                          ),
                          ElevatedButton(
                            onPressed: () => updateBookingStatus('declined'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            ),
                            child: const Text('Decline'),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
    );
  }
}
