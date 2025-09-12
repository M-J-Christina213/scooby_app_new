// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scooby_app_new/models/booking_model.dart';
import 'package:scooby_app_new/views/screens/appointment_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scooby_app_new/widgets/message_components.dart';

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

  static const Color kPrimary = Color(0xFF842EAC);
  static const Color kCardShadow = Color(0x1F000000);

  final DateFormat _dateFmt = DateFormat('EEE, MMM d');

  List<Booking> _upcoming = [];
  List<Booking> _past = [];

 
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchUpcoming();
  }

  Future<void> fetchUpcoming() async {
    setState(() => loading = true);
    try {
      final resp = await supabase
          .from('bookings')
          .select('*, pets(name)')
          .eq('service_provider_email', widget.providerEmail)
          .eq('status', 'accepted')
          .order('date', ascending: true);

      final rows = (resp as List<dynamic>? ?? [])
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList();

      final all = rows.map((map) {
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

      final now = DateTime.now();
      final List<Booking> upcoming = [];
      final List<Booking> past = [];

      for (final b in all) {
        final dt = _combineDateAndTime(b.date, b.time) ?? b.date;
        if (dt.isBefore(now)) {
          past.add(b);
        } else {
          upcoming.add(b);
        }
      }

      upcoming.sort((a, b) {
        final da = _combineDateAndTime(a.date, a.time) ?? a.date;
        final db = _combineDateAndTime(b.date, b.time) ?? b.date;
        return da.compareTo(db);
      });

      past.sort((a, b) {
        final da = _combineDateAndTime(a.date, a.time) ?? a.date;
        final db = _combineDateAndTime(b.date, b.time) ?? b.date;
        return db.compareTo(da);
      });

      if (!mounted) return;
      setState(() {
        _upcoming = upcoming;
        _past = past;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load appointments: $e'),
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
              onRefresh: fetchUpcoming,
              child: (_upcoming.isEmpty && _past.isEmpty)
                  ? ListView(
                      padding: const EdgeInsets.only(top: 120),
                      children: [
                        Icon(Icons.event_available,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Center(
                          child: Text(
                            'No accepted bookings yet',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            'Accepted appointments will appear here.',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        if (_upcoming.isNotEmpty) ...[
                          _sectionHeader('Upcoming'),
                          const SizedBox(height: 8),
                          ..._upcoming
                              .map((b) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 12.0),
                                    child: _bookingCard(b, isPast: false),
                                  )),
                           
                          const SizedBox(height: 8),
                        ],
                        if (_past.isNotEmpty) ...[
                          _sectionHeader('Past'),
                          const SizedBox(height: 8),
                          ..._past
                              .map((b) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 12.0),
                                    child: _bookingCard(b, isPast: true),
                                  ))
                          
                        ],
                      ],
                    ),
            ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 18,
          decoration: BoxDecoration(
            color: kPrimary,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _bookingCard(Booking b, {required bool isPast}) {
    final apptDt = _combineDateAndTime(b.date, b.time);
    final dateStr = _dateFmt.format(b.date);

    final chipText = isPast ? 'Completed' : 'Upcoming';
    final chipBg =
        isPast ? Colors.grey.withOpacity(.12) : kPrimary.withOpacity(.10);
    final chipFg = isPast ? Colors.grey.shade700 : kPrimary;

    final subNote = apptDt != null ? _relative(apptDt) : null;
    final subNoteStyle = TextStyle(
      color: isPast ? Colors.grey.shade600 : Colors.black54,
      fontWeight: FontWeight.w500,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: kCardShadow, blurRadius: 12, offset: Offset(0, 6)),
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
            if (result == true) fetchUpcoming();
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: owner/pet, message icon, chip
                Row(
                  children: [
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
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => MessageSheet(
                            bookingId: b.id,
                            providerEmail: widget.providerEmail,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: chipBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        chipText,
                        style: TextStyle(
                          fontSize: 11,
                          color: chipFg,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Date/time + relative
                Row(
                  children: [
                    const Icon(Icons.event, size: 18, color: Colors.black54),
                    const SizedBox(width: 6),
                    Text(dateStr,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 14),
                    const Icon(Icons.access_time, size: 18, color: Colors.black54),
                    const SizedBox(width: 6),
                    Text(b.time, style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (subNote != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        '• $subNote',
                        style: subNoteStyle,
                      ),
                    ]
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

  // ────────────────────────────────────────────────────────────────────────────
  // Helpers

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
