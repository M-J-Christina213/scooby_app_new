// lib/views/screens/todays_appointments.dart
// lib/views/screens/todays_appointments.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scooby_app_new/models/booking_model.dart';
import 'package:scooby_app_new/views/screens/appointment_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TodayAppointments extends StatefulWidget {
  final String providerEmail;
  final String userId;

  const TodayAppointments({
    super.key,
    required this.providerEmail,
    required this.userId,
  });

  const TodayAppointments({
    super.key,
    required this.providerEmail,
    required this.userId,
  });

  @override
  State<TodayAppointments> createState() => _TodayAppointmentsState();
}

class _TodayAppointmentsState extends State<TodayAppointments> {
  final supabase = Supabase.instance.client;

  static const Color kPrimary = Color(0xFF842EAC);
  static const Color kCardShadowColor = Color(0x1F000000); // subtle shadow

  final DateFormat _dateFmt = DateFormat('EEE, MMM d');


  static const Color kPrimary = Color(0xFF842EAC);
  static const Color kCardShadowColor = Color(0x1F000000); // subtle shadow

  final DateFormat _dateFmt = DateFormat('EEE, MMM d');

  List<Booking> bookings = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchToday();
  }

  Future<void> fetchToday() async {
    setState(() => loading = true);
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final tomorrowStart = todayStart.add(const Duration(days: 1));

      final resp = await supabase
          .from('bookings')
          .select('*, pets(name)')
          .eq('service_provider_email', widget.providerEmail)
          .eq('status', 'accepted')
          .gte('date', todayStart.toIso8601String())
          .lt('date', tomorrowStart.toIso8601String())
          .order('date', ascending: true);
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final tomorrowStart = todayStart.add(const Duration(days: 1));

      final resp = await supabase
          .from('bookings')
          .select('*, pets(name)')
          .eq('service_provider_email', widget.providerEmail)
          .eq('status', 'accepted')
          .gte('date', todayStart.toIso8601String())
          .lt('date', tomorrowStart.toIso8601String())
          .order('date', ascending: true);

      final rows = (resp as List<dynamic>? ?? [])
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList();

      final list = rows.map((map) {
        String petName = '';
        final petsJoin = map['pets'];
        if (petsJoin is List && petsJoin.isNotEmpty) {
          petName = (petsJoin.first['name'] ?? '') as String;
        } else if (petsJoin is Map) {
          petName = (petsJoin['name'] ?? '') as String;
        }
        map['pet_name'] = petName;
        return Booking.fromMap(map);
      }).toList(growable: false);

      list.sort((a, b) {
        final da = _combineDateAndTime(a.date, a.time) ?? a.date;
        final db = _combineDateAndTime(b.date, b.time) ?? b.date;
        return da.compareTo(db);
      });

      if (!mounted) return;
      setState(() => bookings = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load today\'s appointments: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
      final rows = (resp as List<dynamic>? ?? [])
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList();

      final list = rows.map((map) {
        String petName = '';
        final petsJoin = map['pets'];
        if (petsJoin is List && petsJoin.isNotEmpty) {
          petName = (petsJoin.first['name'] ?? '') as String;
        } else if (petsJoin is Map) {
          petName = (petsJoin['name'] ?? '') as String;
        }
        map['pet_name'] = petName;
        return Booking.fromMap(map);
      }).toList(growable: false);

      list.sort((a, b) {
        final da = _combineDateAndTime(a.date, a.time) ?? a.date;
        final db = _combineDateAndTime(b.date, b.time) ?? b.date;
        return da.compareTo(db);
      });

      if (!mounted) return;
      setState(() => bookings = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load today\'s appointments: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: fetchToday,
        child: bookings.isEmpty
            ? ListView(
          padding: const EdgeInsets.only(top: 120),
          children: [
            Icon(Icons.today, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'No appointments today',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Accepted bookings for today will appear here.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],
        )
            : ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: bookings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _todayCard(bookings[i]),
        ),
      ),
    );
  }

  Widget _todayCard(Booking b) {
    final apptDt = _combineDateAndTime(b.date, b.time);
    final dateStr = _dateFmt.format(b.date);
    final petInitial = (b.petName.isNotEmpty ? b.petName[0] : 'P').toUpperCase();

    return Container(
      // solid white card + shadow
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: kCardShadowColor,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
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
            if (!mounted) return;
            if (result == true) fetchToday();
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: fetchToday,
        child: bookings.isEmpty
            ? ListView(
          padding: const EdgeInsets.only(top: 120),
          children: [
            Icon(Icons.today, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'No appointments today',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Accepted bookings for today will appear here.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],
        )
            : ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: bookings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _todayCard(bookings[i]),
        ),
      ),
    );
  }

  Widget _todayCard(Booking b) {
    final apptDt = _combineDateAndTime(b.date, b.time);
    final dateStr = _dateFmt.format(b.date);
    final petInitial = (b.petName.isNotEmpty ? b.petName[0] : 'P').toUpperCase();

    return Container(
      // solid white card + shadow
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: kCardShadowColor,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
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
            if (!mounted) return;
            if (result == true) fetchToday();
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: kPrimary.withOpacity(.08),
                      child: Text(
                        petInitial,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: kPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${b.ownerName} • ${b.petName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.message, color: kPrimary),
                      onPressed: () {
                        _openMessageSheet(b);
                      }
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 11,
                          color: kPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // date & time
                Row(
                  children: [
                    const Icon(Icons.event, size: 18, color: Colors.black54),
                    const SizedBox(width: 6),
                    Text(dateStr, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 14),
                    const Icon(Icons.access_time, size: 18, color: Colors.black54),
                    const SizedBox(width: 6),
                    Text(b.time, style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (apptDt != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        '• ${_relative(apptDt)}',
                        style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // ====== Messaging Bottom Sheet ======
  void _openMessageSheet(Booking b) {
    final messageController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: SizedBox(
          height: 400,
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Text('Messages', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Divider(),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: supabase
                      .from('messages')
                      .stream(primaryKey: ['id'])
                      .eq('booking_id', b.id)
                      .order('created_at', ascending: true),
                  builder: (context, snapshot) {
                    final msgs = snapshot.data ?? [];
                    return ListView.builder(
                      itemCount: msgs.length,
                      itemBuilder: (_, i) {
                        final m = msgs[i];
                        final isProvider = m['sender'] == widget.providerEmail;
                        return Align(
                          alignment: isProvider ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isProvider ? kPrimary : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              m['content'],
                              style: TextStyle(color: isProvider ? Colors.white : Colors.black87),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: kPrimary),
                      onPressed: () async {
                        final text = messageController.text.trim();
                        if (text.isEmpty) return;
                        messageController.clear();
                        await supabase.from('messages').insert({
                          'booking_id': b.id,
                          'sender': widget.providerEmail,
                          'receiver': b.ownerEmail,
                          'content': text,
                          'created_at': DateTime.now().toIso8601String(),
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // helpers

  TimeOfDay? _parseTimeFlexible(String? raw) {
    if (raw == null) return null;
    final s = raw.trim().toUpperCase();

    final m24 = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?$').firstMatch(s);
    if (m24 != null) {
      final h = int.tryParse(m24.group(1)!);
      final m = int.tryParse(m24.group(2)!);
      if (h != null && m != null && h >= 0 && h < 24 && m >= 0 && m < 60) {
        return TimeOfDay(hour: h, minute: m);
      }
    }

    final m12 = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$').firstMatch(s);
    if (m12 != null) {
      int h = int.tryParse(m12.group(1)!) ?? 0;
      final m = int.tryParse(m12.group(2)!) ?? 0;
      final ap = m12.group(3)!;
      if (h == 12) h = 0;
      if (ap == 'PM') h += 12;
      if (h >= 0 && h < 24 && m >= 0 && m < 60) {
        return TimeOfDay(hour: h, minute: m);
      }
    }
    return null;
  }

  DateTime? _combineDateAndTime(DateTime date, String timeStr) {
    final tod = _parseTimeFlexible(timeStr);
    if (tod == null) return null;
    return DateTime(date.year, date.month, date.day, tod.hour, tod.minute);
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  String _relative(DateTime when) {
    final now = DateTime.now();
    Duration diff = when.difference(now);
    final isPast = diff.isNegative;
    diff = diff.abs();

    final d = diff.inDays;
    final h = diff.inHours % 24;
    final m = diff.inMinutes % 60;

    String core;
    if (d > 0) {
      core = '$d d ${_two(h)}h';
    } else if (h > 0) {
      core = '$h h ${_two(m)}m';
    } else {
      core = '$m m';
    }

    return isPast ? '$core ago' : 'in $core';
  }
}