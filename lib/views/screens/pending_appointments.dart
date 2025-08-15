// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scooby_app_new/models/booking_model.dart';
import 'package:scooby_app_new/views/screens/appointment_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PendingAppointments extends StatefulWidget {
  final String providerEmail;
  final String userId; 


  const PendingAppointments({super.key, required this.providerEmail, required this.userId});

  @override
  State<PendingAppointments> createState() => _PendingAppointmentsState();
}

class _PendingAppointmentsState extends State<PendingAppointments> {
  final supabase = Supabase.instance.client;

  List<Booking> bookings = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchPending();
  }

  Future<void> fetchPending() async {
    setState(() => loading = true);
    final resp = await supabase
        .from('bookings')
        .select('*, pets(name)')
        .eq('service_provider_email', widget.providerEmail)
        .eq('status', 'pending')
        .order('date', ascending: true);

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

  Future<void> updateBookingStatus(String bookingId, String status) async {
    await supabase.from('bookings').update({'status': status}).eq('id', bookingId);
    fetchPending(); // refresh the list
  }

  Future<void> sendMessage(String bookingId) async {
    final textController = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              maxLines: 3,
              decoration: const InputDecoration(
                  hintText: 'Type your message...', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                if (textController.text.trim().isEmpty) return;
                await supabase.from('messages').insert({
                  'booking_id': bookingId,
                  'sender': 'provider',
                  'body': textController.text.trim(),
                  'created_at': DateTime.now().toUtc().toIso8601String(),
                });
                textController.clear();
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Message sent successfully')),
                );
                Navigator.pop(ctx);
              },
              icon: const Icon(Icons.send),
              label: const Text('Send'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchPending,
              child: bookings.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 200),
                        Center(child: Text('No pending bookings'))
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: bookings.length,
                      itemBuilder: (context, i) {
                        final b = bookings[i];
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top row: owner info + message icon
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => AppointmentDetailScreen(
                                                bookingId: b.id,
                                                providerEmail: widget.providerEmail,
                                                userId: widget.userId,   
                                               
                                              ),
                                            ),
                                          );
                                          if (result == true) fetchPending();
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Text(
                                            '${b.ownerName} • ${b.petName}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.deepPurple,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => sendMessage(b.id),
                                      icon: const Icon(Icons.message, color: Colors.deepPurple),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${DateFormat.yMMMd().format(b.date)} • ${b.time}',
                                  style: const TextStyle(color: Colors.black87),
                                ),
                                const SizedBox(height: 12),
                                // Horizontal Accept / Decline buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => updateBookingStatus(b.id, 'accepted'),
                                      icon: const Icon(Icons.check),
                                      label: const Text('Accept'),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () => updateBookingStatus(b.id, 'declined'),
                                      icon: const Icon(Icons.close),
                                      label: const Text('Decline'),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );

                      },
                    ),
            ),
    );
  }
}
