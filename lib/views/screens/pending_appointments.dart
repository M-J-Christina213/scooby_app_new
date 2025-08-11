
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scooby_app_new/models/booking_model.dart';
import 'package:scooby_app_new/views/screens/appointment_detail_screen.dart';
import 'package:scooby_app_new/widgets/success_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';



class PendingAppointments extends StatefulWidget {
  final String providerEmail;
  const PendingAppointments({super.key, required this.providerEmail});

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
    fetchPending();
  }

  Future<void> sendQuickMessage(String bookingId, String message) async {
    // simple messages table insert: messages( id, booking_id, sender, body, created_at )
    await supabase.from('messages').insert({
      'booking_id': bookingId,
      'sender': 'provider',
      'body': message,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message sent')));
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
                      children: const [SizedBox(height: 200), Center(child: Text('No pending bookings'))],
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
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            title: Text('${b.ownerName} • ${b.petName}'),
                            subtitle: Text('${DateFormat.yMMMd().format(b.date)} • ${b.time}\n${b.ownerEmail}'),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check_circle, color: Colors.green),
                                  onPressed: () => showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Accept booking?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                        ElevatedButton(
                                          onPressed: () async {
                                            Navigator.pop(context);
                                            await updateBookingStatus(b.id, 'accepted');
                                            // show success UI
                                            showGeneralDialog(
                                              context: context,
                                              pageBuilder: (_, __, ___) => const SizedBox.shrink(),
                                              barrierDismissible: true,
                                              transitionBuilder: (_, anim, __, child) {
                                                return Transform.scale(
                                                  scale: Curves.easeOut.transform(anim.value),
                                                  child: Opacity(opacity: anim.value, child: const SuccessDialog()),
                                                );
                                              },
                                            );
                                          },
                                          child: const Text('Yes'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.red),
                                  onPressed: () => showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Decline booking?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                          onPressed: () async {
                                            Navigator.pop(context);
                                            await updateBookingStatus(b.id, 'declined');
                                            fetchPending();
                                          },
                                          child: const Text('Decline'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.message),
                                  onPressed: () async {
                                    final custom = await showModalBottomSheet<String>(
                                      context: context,
                                      builder: (ctx) {
                                        final controller = TextEditingController(text: "Please don't bath the pet for 2-3 days.");
                                        return Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextField(controller: controller, maxLines: 3),
                                              const SizedBox(height: 12),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(ctx, controller.text),
                                                child: const Text('Send'),
                                              )
                                            ],
                                          ),
                                        );
                                      },
                                    );

                                    if (custom != null && custom.trim().isNotEmpty) {
                                      await sendQuickMessage(b.id, custom);
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.visibility),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AppointmentDetailScreen(bookingId: b.id, providerEmail: widget.providerEmail),
                                    ),
                                  ),
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