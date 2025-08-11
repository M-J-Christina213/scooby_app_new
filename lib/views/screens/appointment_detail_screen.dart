import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scooby_app_new/widgets/pet_profile_card.dart';
import 'package:scooby_app_new/widgets/section_title.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final String bookingId;
  final String providerEmail;
  const AppointmentDetailScreen({super.key, required this.bookingId, required this.providerEmail});

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? booking;
  List<dynamic> pet = [];
  List<dynamic> updates = [];
  List<dynamic> messages = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  Future<void> loadAll() async {
    setState(() => loading = true);
    final resp = await supabase
        .from('bookings')
        .select('*, pets(*), appointment_updates(*), messages(*)')
        .eq('id', widget.bookingId)
        .maybeSingle();

    if (resp != null) {
      booking = Map<String, dynamic>.from(resp);
      pet = booking?['pets'] ?? [];
      updates = booking?['appointment_updates'] ?? [];
      messages = booking?['messages'] ?? [];
    }

    setState(() => loading = false);
  }

  Future<void> addUpdate(String description, DateTime when) async {
    await supabase.from('appointment_updates').insert({
      'booking_id': widget.bookingId,
      'update_date': when.toUtc().toIso8601String(),
      'description': description,
    });
    await loadAll();
  }

  Future<void> sendMessage(String body) async {
    await supabase.from('messages').insert({
      'booking_id': widget.bookingId,
      'sender': 'provider',
      'body': body,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
    await loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(booking?['owner_name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Contact: ${booking?['owner_phone'] ?? ''}'),
                          const SizedBox(height: 8),
                          Text('Date: ${booking != null ? DateFormat.yMMMd().format(DateTime.parse(booking!['date'])) : ''}'),
                          const SizedBox(height: 8),
                          Text('Time: ${booking?['time'] ?? ''}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (pet.isNotEmpty) PetProfileCard(petData: pet[0]),
                  const SizedBox(height: 12),
                  SectionTitle(title: 'Treatment / Updates'),
                  ...updates.map((u) => ListTile(
                        leading: const Icon(Icons.medical_information),
                        title: Text(u['description'] ?? ''),
                        subtitle: Text(u['update_date'] != null ? DateFormat.yMMMd().format(DateTime.parse(u['update_date'])) : ''),
                      )),
                  ElevatedButton(
                    onPressed: () async {
                      final res = await showDialog<Map<String, dynamic>>(
                        context: context,
                        builder: (ctx) {
                          final desc = TextEditingController();
                          DateTime chosen = DateTime.now();
                          return AlertDialog(
                            title: const Text('Add Update'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(controller: desc, decoration: const InputDecoration(hintText: 'e.g., Rabies vaccine given')),
                                const SizedBox(height: 8),
                                Row(children: [
                                  Text(DateFormat.yMMMd().format(chosen)),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () async {
                                      final d = await showDatePicker(context: ctx, initialDate: chosen, firstDate: DateTime(2000), lastDate: DateTime(2100));
                                      if (d != null) chosen = d;
                                    },
                                    child: const Text('Change date'),
                                  )
                                ])
                              ],
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                              ElevatedButton(onPressed: () => Navigator.pop(ctx, {'desc': desc.text, 'date': chosen}), child: const Text('Add')),
                            ],
                          );
                        },
                      );

                      if (res != null && (res['desc'] as String).trim().isNotEmpty) {
                        await addUpdate(res['desc'], res['date']);
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update added')));
                      }
                    },
                    child: const Text('Add Update'),
                  ),
                  const SizedBox(height: 12),
                  SectionTitle(title: 'Messages'),
                  ...messages.map((m) => ListTile(
                        leading: m['sender'] == 'provider' ? const Icon(Icons.person) : const Icon(Icons.person_outline),
                        title: Text(m['body'] ?? ''),
                        subtitle: Text(m['created_at'] != null ? DateFormat.yMMMd().add_jm().format(DateTime.parse(m['created_at'])) : ''),
                      )),
                  ElevatedButton(
                    onPressed: () async {
                      final txt = await showDialog<String>(
                        context: context,
                        builder: (ctx) {
                          final c = TextEditingController();
                          return AlertDialog(
                            title: const Text('Send Message'),
                            content: TextField(controller: c, maxLines: 4),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                              ElevatedButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Send')),
                            ],
                          );
                        },
                      );
                      if (txt != null && txt.trim().isNotEmpty) {
                        await sendMessage(txt.trim());
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message sent')));
                      }
                    },
                    child: const Text('Send Message'),
                  ),
                ],
              ),
            ),
    );
  }
}
