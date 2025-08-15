import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scooby_app_new/models/booking_model.dart';
import 'package:scooby_app_new/views/screens/appointment_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompletedAppointments extends StatefulWidget {
  final String providerEmail;
  final String userId; 
  const CompletedAppointments({super.key, required this.providerEmail, required this.userId});

  @override
  State<CompletedAppointments> createState() => _CompletedAppointmentsState();
}

class _CompletedAppointmentsState extends State<CompletedAppointments> {
  final supabase = Supabase.instance.client;
  List<Booking> bookings = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchCompleted();
  }

  Future<void> fetchCompleted() async {
    setState(() => loading = true);
    final resp = await supabase
        .from('bookings')
        .select('*, pets(name)')
        .eq('service_provider_email', widget.providerEmail)
        .eq('status', 'completed')
        .order('date', ascending: false);

    bookings = (resp as List<dynamic>?)?.map((e) {
      final map = Map<String, dynamic>.from(e);
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
    child: loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: fetchCompleted,
            child: bookings.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 200),
                      Center(child: Text('No completed appointments')),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: bookings.length,
                    itemBuilder: (context, i) {
                      final b = bookings[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text('${b.ownerName} • ${b.petName}'),
                          subtitle: Text('${DateFormat.yMMMd().format(b.date)} • ${b.time}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.history_toggle_off),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AppointmentDetailScreen(
                                  bookingId: b.id,
                                  providerEmail: widget.providerEmail,
                                  userId: widget.userId,  
                                    
                                ),
                              ),
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