// lib/views/screens/pending_appointments.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scooby_app_new/models/booking_model.dart';
import 'package:scooby_app_new/views/screens/appointment_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PendingAppointments extends StatefulWidget {
  final String providerEmail;
  final String userId;

  const PendingAppointments({
    super.key,
    required this.providerEmail,
    required this.userId,
  });

  @override
  State<PendingAppointments> createState() => _PendingAppointmentsState();
}

class _PendingAppointmentsState extends State<PendingAppointments> {
  final supabase = Supabase.instance.client;

  static const Color kPrimary = Color(0xFF6A0DAD);
  static const Color kCardShadow = Color(0x1F000000);
  static const EdgeInsets kPagePadding = EdgeInsets.all(12);

  List<Booking> bookings = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchPending();
  }

  Future<void> fetchPending() async {
    setState(() => loading = true);
    try {
      final resp = await supabase
          .from('bookings')
          .select('*, pets(name)')
          .eq('service_provider_email', widget.providerEmail)
          .eq('status', 'pending')
          .order('date', ascending: true);

      final list = (resp as List<dynamic>? ?? [])
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList();

      final parsed = list.map((map) {
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

      if (!mounted) return;
      setState(() => bookings = parsed);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load appointments: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    final confirmed = await _confirm(
      title: status == 'accepted' ? 'Accept booking?' : 'Decline booking?',
      message: status == 'accepted'
          ? 'This will confirm the appointment.'
          : 'This will reject the appointment.',
      confirmText: status == 'accepted' ? 'Accept' : 'Decline',
      confirmColor: status == 'accepted' ? Colors.green : Colors.red,
    );
    if (confirmed != true) return;

    try {
      await supabase.from('bookings').update({'status': status}).eq('id', bookingId);

      if (!mounted) return;
      await fetchPending();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'accepted' ? 'Appointment accepted' : 'Appointment declined',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
          status == 'accepted' ? Colors.green.shade600 : Colors.red.shade600,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<void> openMessages(Booking b) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true, // keep safe on devices with notches
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _MessageSheet(
          bookingId: b.id,
          providerEmail: widget.providerEmail,
        );
      },
    );
  }

  // ────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: fetchPending,
        child: bookings.isEmpty
            ? ListView(
          padding: const EdgeInsets.only(top: 120),
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'No pending bookings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'When you get new requests, they’ll show up here.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],
        )
            : ListView.separated(
          padding: kPagePadding,
          itemCount: bookings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _buildBookingCard(bookings[i]),
        ),
      ),
    );
  }

  Widget _buildBookingCard(Booking b) {
    final dateStr = DateFormat('EEE, MMM d').format(b.date);
    final petInitial = (b.petName.isNotEmpty ? b.petName[0] : 'P').toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: kCardShadow, blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
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
            if (result == true) fetchPending();
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: kPrimary.withOpacity(.1),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Owner • Pet
                          Text(
                            '${b.ownerName} • ${b.petName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Latest message preview (async)
                          _LastMessagePreview(bookingId: b.id),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Pending',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => openMessages(b),
                      icon: const Icon(Icons.message, color: kPrimary),
                      tooltip: 'Messages',
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Date & time row
                Row(
                  children: [
                    const Icon(Icons.event, size: 18, color: Colors.black54),
                    const SizedBox(width: 6),
                    Text(dateStr, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 14),
                    const Icon(Icons.access_time, size: 18, color: Colors.black54),
                    const SizedBox(width: 6),
                    Text(b.time, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Actions row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => updateBookingStatus(b.id, 'declined'),
                        icon: const Icon(Icons.close, size: 18, color: Colors.red),
                        label: const Text(
                          'Decline',
                          style:
                          TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => updateBookingStatus(b.id, 'accepted'),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text(
                          'Accept',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Helpers

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}

/// Small async preview under the card title
class _LastMessagePreview extends StatelessWidget {
  const _LastMessagePreview({required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context) {
    final sb = Supabase.instance.client;
    return FutureBuilder(
      future: sb
          .from('messages')
          .select('body, sender, created_at')
          .eq('booking_id', bookingId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data == null) {
          return Text(
            'No messages yet',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          );
        }
        final m = Map<String, dynamic>.from(snap.data as Map);
        final isProv = (m['sender'] as String?) == 'provider';
        final body = (m['body'] as String?) ?? '';
        final prefix = isProv ? 'You: ' : 'Customer: ';
        return Text(
          '$prefix${_truncate(body, 60)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
        );
      },
    );
  }

  static String _truncate(String s, int n) =>
      s.length <= n ? s : '${s.substring(0, n - 1)}…';
}

// ──────────────────────────────────────────────────────────────────────────────
// Messaging drawer (realtime + reply/quote + keyboard-safe)

class _MessageSheet extends StatefulWidget {
  const _MessageSheet({
    required this.bookingId,
    required this.providerEmail,
  });

  final String bookingId;
  final String providerEmail;

  @override
  State<_MessageSheet> createState() => _MessageSheetState();
}

class _MessageSheetState extends State<_MessageSheet>
    with WidgetsBindingObserver {
  static const Color kPrimary = Color(0xFF6A0DAD);

  final supabase = Supabase.instance.client;
  final _text = TextEditingController();
  final _scroll = ScrollController();

  List<Map<String, dynamic>> _msgs = [];
  Map<String, dynamic>? _replyTo;

  // de-dupe for realtime echoes
  final Set<String> _seen = <String>{};
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _subscribe();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    try {
      _channel?.unsubscribe();
    } catch (_) {
      try {
        Supabase.instance.client.removeChannel(_channel!);
      } catch (_) {}
    }
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // auto-scroll when keyboard opens/closes
  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _load() async {
    final res = await supabase
        .from('messages')
        .select()
        .eq('booking_id', widget.bookingId)
        .order('created_at', ascending: true);

    final list = (res as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    for (final m in list) {
      _seen.add(_key(m));
    }

    setState(() => _msgs = list);
    _scrollToBottom();
  }

  void _subscribe() {
    final ch = supabase.channel('public:messages:booking:${widget.bookingId}');

    ch.on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: 'INSERT',
        schema: 'public',
        table: 'messages',
        filter: 'booking_id=eq.${widget.bookingId}',
      ),
          (payload, [ref]) {
        final row = payload.newRecord;
        if (row == null || !mounted) return;
        final m = Map<String, dynamic>.from(row);
        final k = _key(m);
        if (_seen.contains(k)) return; // avoid duplicates
        _seen.add(k);
        setState(() => _msgs.add(m));
        _scrollToBottom();
      },
    );

    ch.subscribe(); // returns void in current SDK
    _channel = ch;
  }

  String _key(Map<String, dynamic> m) =>
      '${m['created_at']}_${m['sender']}_${(m['body'] ?? '').hashCode}';

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _quote(String text) {
    final lines = text.trim().split('\n');
    final preview = lines.take(2).join(' ');
    return '> ${preview.length > 80 ? '${preview.substring(0, 79)}…' : preview}\n\n';
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    if (body.isEmpty) return;

    final nowIso = DateTime.now().toUtc().toIso8601String();
    final fullBody = _replyTo != null
        ? '${_quote(_replyTo!['body'] as String? ?? '')}$body'
        : body;

    // optimistic append so it shows immediately
    final optimistic = {
      'booking_id': widget.bookingId,
      'sender': 'provider',
      'body': fullBody,
      'created_at': nowIso,
    };
    final k = _key(optimistic);
    _seen.add(k);
    setState(() {
      _msgs.add(optimistic);
      _text.clear();
      _replyTo = null;
    });
    _scrollToBottom();

    try {
      // keep same created_at so the realtime event matches our key
      await supabase.from('messages').insert(optimistic);
    } catch (e) {
      // roll back optimistic item on failure
      setState(() => _msgs.removeWhere((m) => _key(m) == k));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = const Radius.circular(20);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset), // keeps composer above keyboard
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .78,
        minChildSize: .5,
        maxChildSize: .95,
        builder: (_, controller) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: radius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                // Handle
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                const SizedBox(height: 10),
                // Title
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Messages',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),

                // Messages list
                Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    itemCount: _msgs.length,
                    itemBuilder: (ctx, i) {
                      final m = _msgs[i];
                      final isProvider = (m['sender'] as String?) == 'provider';
                      final time = _formatTime(m['created_at']);
                      final body = (m['body'] as String?) ?? '';

                      return GestureDetector(
                        onLongPress: () => setState(() => _replyTo = m),
                        child: Align(
                          alignment: isProvider
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            constraints: const BoxConstraints(maxWidth: 320),
                            decoration: BoxDecoration(
                              color: isProvider
                                  ? kPrimary.withOpacity(.10)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(14),
                                topRight: const Radius.circular(14),
                                bottomLeft: isProvider
                                    ? const Radius.circular(14)
                                    : const Radius.circular(4),
                                bottomRight: isProvider
                                    ? const Radius.circular(4)
                                    : const Radius.circular(14),
                              ),
                              border: Border.all(
                                color: isProvider
                                    ? kPrimary.withOpacity(.25)
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _MaybeQuote(text: body),
                                Text(body, style: const TextStyle(fontSize: 14)),
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    time,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
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

                // Reply banner (if any)
                if (_replyTo != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kPrimary.withOpacity(.18)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.reply, size: 16, color: kPrimary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _preview(_replyTo!['body'] as String? ?? ''),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => setState(() => _replyTo = null),
                          splashRadius: 18,
                        )
                      ],
                    ),
                  ),

                // Composer
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _text,
                            minLines: 1,
                            maxLines: 5,
                            onTap: _scrollToBottom,
                            decoration: InputDecoration(
                              hintText:
                              _replyTo == null ? 'Type a message…' : 'Replying…',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                const BorderSide(color: kPrimary, width: 1.4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 44,
                          width: 48,
                          child: ElevatedButton(
                            onPressed: _send,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Icon(Icons.send, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTime(dynamic createdAt) {
    try {
      final dt = DateTime.parse(createdAt as String).toLocal();
      return DateFormat('MMM d • h:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  String _preview(String text) {
    final t = text.trim();
    return t.length <= 100 ? t : '${t.substring(0, 100)}…';
  }
}

/// Renders the quoted block if the body starts with a markdown style quote
class _MaybeQuote extends StatelessWidget {
  const _MaybeQuote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    if (!text.trimLeft().startsWith('> ')) return const SizedBox.shrink();

    // Extract the first quoted lines (until blank line)
    final lines = text.split('\n');
    final quoted = <String>[];
    for (final l in lines) {
      if (l.startsWith('> ')) {
        quoted.add(l.substring(2));
      } else {
        break;
      }
    }

    if (quoted.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.reply, size: 14, color: Colors.amber),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              quoted.join(' '),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade800,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
