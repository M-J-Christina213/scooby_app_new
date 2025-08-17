import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scooby_app_new/models/booking_model.dart';
import 'package:scooby_app_new/views/screens/appointment_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpcomingAppointments extends StatefulWidget {
  final String providerEmail;
  final String userId;

  const UpcomingAppointments({
    super.key,
    required this.providerEmail,
    required this.userId,
  });

  @override
  State<UpcomingAppointments> createState() => _UpcomingAppointmentsState();
}

class _UpcomingAppointmentsState extends State<UpcomingAppointments> {
  final supabase = Supabase.instance.client;
  List<Booking> bookings = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchUpcoming();
  }

  Future<void> fetchUpcoming() async {
    setState(() => loading = true);

    final resp = await supabase
        .from('bookings')
        .select('*, pets(name)')
        .eq('service_provider_email', widget.providerEmail)
        .eq('status', 'accepted') // ✅ accepted = upcoming
        .order('date', ascending: true);

    bookings = (resp as List<dynamic>?)?.map((e) {
          final map = Map<String, dynamic>.from(e);
          String petName = '';
          if (map.containsKey('pets') &&
              map['pets'] is List &&
              map['pets'].isNotEmpty) {
            petName = (map['pets'][0]['name'] ?? '');
          }
          map['pet_name'] = petName;
          return Booking.fromMap(map);
        }).toList(growable: false) ??
        [];

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchUpcoming,
              child: bookings.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 200),
                        Center(
                          child: Text(
                            'No upcoming appointments',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: bookings.length,
                      itemBuilder: (context, i) {
                        final b = bookings[i];
                        return Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AppointmentDetailScreen(
                                  bookingId: b.id,
                                  providerEmail: widget.providerEmail,
                                  userId: widget.userId,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Owner + Pet Info
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: Colors.deepPurple[100],
                                        child: const Icon(
                                          Icons.pets,
                                          color: Colors.deepPurple,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          '${b.ownerName} • ${b.petName}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Date & Time
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          size: 18, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(
                                        DateFormat.yMMMd().format(b.date),
                                        style: const TextStyle(
                                            fontSize: 15, color: Colors.black87),
                                      ),
                                      const SizedBox(width: 16),
                                      const Icon(Icons.access_time,
                                          size: 18, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(
                                        b.time,
                                        style: const TextStyle(
                                            fontSize: 15, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  // Status Badge
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Upcoming',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.deepPurple,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
