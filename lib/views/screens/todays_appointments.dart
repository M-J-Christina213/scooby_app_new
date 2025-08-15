import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scooby_app_new/models/booking_model.dart';
import 'package:scooby_app_new/views/screens/appointment_detail_screen.dart';
import 'package:scooby_app_new/widgets/appointment_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TodayAppointments extends StatefulWidget {
  final String providerEmail;
  final String userId;
  const TodayAppointments({super.key, required this.providerEmail, required this.userId, 
    });

  @override
  State<TodayAppointments> createState() => _TodayAppointmentsState();
}

class _TodayAppointmentsState extends State<TodayAppointments> {
  final supabase = Supabase.instance.client;
  List<Booking> bookings = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchToday();
  }

  Future<void> fetchToday() async {
    setState(() => loading = true);
    final start = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final resp = await supabase
        .from('bookings')
        .select('*, pets(name)')
        .eq('service_provider_email', widget.providerEmail)
        .eq('date::date', start)
        .order('date', ascending: true);

    bookings = (resp as List<dynamic>?)?.map((e) {
      final map = Map<String, dynamic>.from(e);
      // extract pet name if joined
      String petName = '';
      if (map.containsKey('pets') && map['pets'] is List && map['pets'].isNotEmpty) {
        petName = (map['pets'][0]['name'] ?? '');
      }
      map['pet_name'] = petName;
      return Booking.fromMap(map);
    }).toList(growable: false) ?? [];

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Today', style: Theme.of(context).textTheme.headlineSmall),
                    Text(DateFormat.yMMMMd().format(DateTime.now())),
                  ],
                ),
                IconButton(
                  onPressed: fetchToday,
                  icon: const Icon(Icons.refresh),
                )
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : bookings.isEmpty
                    ? const Center(child: Text('No appointments today'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: bookings.length,
                        itemBuilder: (context, i) {
                          final b = bookings[i];
                          return AppointmentCard(
                            booking: b,
                            onView: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AppointmentDetailScreen(bookingId: b.id, providerEmail: widget.providerEmail, userId: widget.userId,  
                                 ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}