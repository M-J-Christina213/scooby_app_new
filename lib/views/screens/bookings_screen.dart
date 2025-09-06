// lib/views/screens/bookings_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

enum _Filter { all, upcoming, past, pending, confirmed, cancelled }

class _BookingsScreenState extends State<BookingsScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  String? _ownerId;
  _Filter _filter = _Filter.upcoming;

  // Messages summary per booking
  final Map<String, Map<String, dynamic>> _lastMsg = {}; // bookingId -> {body, sender, created_at}
  final Map<String, int> _msgCount = {}; // bookingId -> count

  @override
  void initState() {
    super.initState();
    _fetchOwnerIdAndBookings();
  }

  // ─────────────────────────── Data ───────────────────────────

  Future<void> _fetchOwnerIdAndBookings() async {
    setState(() => _isLoading = true);

    try {
      final authUserId = supabase.auth.currentUser?.id;
      if (authUserId == null) {
        _showSnack('No logged-in user found.');
        setState(() => _isLoading = false);
        return;
      }

      // Get ownerId from pet_owners
      final ownerRow = await supabase
          .from('pet_owners')
          .select('id')
          .eq('user_id', authUserId)
          .maybeSingle();

      final ownerId = ownerRow?['id'] as String?;
      if (ownerId == null) {
        _showSnack('No pet owner found for this user.');
        setState(() => _isLoading = false);
        return;
      }

      _ownerId = ownerId;
      await _fetchBookings();
    } catch (e) {
      _showSnack('Error fetching owner/bookings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchBookings() async {
    if (_ownerId == null) return;

    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('bookings')
          .select('*, pets(name)')
          .eq('owner_id', _ownerId)
          .order('date', ascending: true);

      final list = List<Map<String, dynamic>>.from(data as List);

      // Extract pet_name robustly
      for (final m in list) {
        String petName = '';
        final p = m['pets'];
        if (p is List && p.isNotEmpty) {
          petName = (p.first['name'] ?? '') as String;
        } else if (p is Map) {
          petName = (p['name'] ?? '') as String;
        }
        m['pet_name'] = petName;
      }

      // Sort by combined DateTime (date + time)
      list.sort((a, b) {
        final da = _bookingStart(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = _bookingStart(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return da.compareTo(db);
      });

      setState(() {
        _bookings = list;
        _isLoading = false;
      });

      // Fetch message summaries for these bookings
      await _fetchMessagesSummary(list.map((e) => e['id'] as String).toList());
    } catch (e) {
      _showSnack('Failed to fetch bookings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMessagesSummary(List<String> bookingIds) async {
    if (bookingIds.isEmpty) return;

    try {
      final rows = await supabase
          .from('messages')
          .select('booking_id, sender, body, created_at')
          .in_('booking_id', bookingIds)
          .order('created_at', ascending: false);

      _lastMsg.clear();
      _msgCount.clear();

      for (final r in rows as List) {
        final m = Map<String, dynamic>.from(r as Map);
        final id = (m['booking_id'] ?? '').toString();
        _msgCount[id] = (_msgCount[id] ?? 0) + 1;
        // first row we encounter per id is the latest (descending order)
        _lastMsg.putIfAbsent(id, () => m);
      }
      if (mounted) setState(() {});
    } catch (_) {
      // ignore; bookings still show
    }
  }

  // ───────────────────────── Helpers ─────────────────────────

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  DateTime? _bookingStart(Map<String, dynamic> b) {
    try {
      final rawDate = b['date'];
      final rawTime = (b['time'] ?? '').toString();

      DateTime date =
      rawDate is DateTime ? rawDate : DateTime.parse(rawDate.toString());

      final tod = _parseTimeFlexible(rawTime);
      if (tod == null) return date;

      return DateTime(date.year, date.month, date.day, tod.hour, tod.minute)
          .toLocal();
    } catch (_) {
      return null;
    }
  }

  TimeOfDay? _parseTimeFlexible(String? raw) {
    if (raw == null) return null;
    String s = raw.trim().toUpperCase();

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

  String _relative(DateTime when) {
    final now = DateTime.now();
    Duration diff = now.difference(when);
    final past = diff.inSeconds >= 0;
    diff = diff.abs();

    if (diff.inDays > 0) return past ? '${diff.inDays}d ago' : 'in ${diff.inDays}d';
    if (diff.inHours > 0) return past ? '${diff.inHours}h ago' : 'in ${diff.inHours}h';
    if (diff.inMinutes > 0) return past ? '${diff.inMinutes}m ago' : 'in ${diff.inMinutes}m';
    return past ? 'just now' : 'soon';
  }

  List<Map<String, dynamic>> get _filtered {
    final now = DateTime.now();
    return _bookings.where((b) {
      final s = (b['status'] ?? '').toString().toLowerCase();
      final start = _bookingStart(b);

      switch (_filter) {
        case _Filter.all:
          return true;
        case _Filter.upcoming:
          return start == null ? false : start.isAfter(now);
        case _Filter.past:
          return start == null ? false : start.isBefore(now);
        case _Filter.pending:
          return s == 'pending';
        case _Filter.confirmed:
          return s == 'confirmed' || s == 'accepted';
        case _Filter.cancelled:
          return s == 'cancelled' || s == 'rejected';
      }
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> get _groupedByDay {
    final DateFormat keyFmt = DateFormat('EEEE, MMM d');
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (final b in _filtered) {
      final start = _bookingStart(b);
      final key = start != null ? keyFmt.format(start) : 'Unknown date';
      groups.putIfAbsent(key, () => []).add(b);
    }
    for (final g in groups.values) {
      g.sort((a, b) {
        final da = _bookingStart(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = _bookingStart(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return da.compareTo(db);
      });
    }
    return groups;
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'confirmed' || s == 'accepted') return Colors.green;
    if (s == 'pending') return Colors.orange;
    if (s == 'cancelled' || s == 'rejected') return Colors.red;
    return const Color(0xFF842EAC);
  }

  String _timeLabel(Map<String, dynamic> b) {
    final start = _bookingStart(b);
    if (start == null) {
      return (b['time'] ?? '').toString();
    }
    return DateFormat('h:mm a').format(start);
  }

  // ───────────────────────── Messages UI ─────────────────────────

  Future<void> _openMessagesSheet(String bookingId) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _MessageSheetOwner(
          bookingId: bookingId,
          // Keep the list preview/count in sync live
          onSummary: (last, count) {
            setState(() {
              _lastMsg[bookingId] = last;
              _msgCount[bookingId] = count;
            });
          },
        );
      },
    );
  }

  // ─────────────────────────── UI ───────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _fetchBookings,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
          ? _EmptyState(onRetry: _fetchOwnerIdAndBookings)
          : Column(
        children: [
          const SizedBox(height: 8),
          _FilterBar(
            value: _filter,
            onChanged: (f) => setState(() => _filter = f),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchBookings,
              child: _filtered.isEmpty
                  ? const _NoResults()
                  : ListView(
                padding:
                const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: _groupedByDay.entries.map((entry) {
                  final day = entry.key;
                  final items = entry.value;
                  return Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8),
                        child: Text(
                          day,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      ...items
                          .map((b) => _BookingCard(b))
                          .toList(),
                      const SizedBox(height: 4),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Card builder
  Widget _BookingCard(Map<String, dynamic> b) {
    final bookingId = (b['id'] ?? '').toString();
    final petName = (b['pet_name'] ?? '').toString().trim();
    final ownerName = (b['owner_name'] ?? '').toString().trim();
    final provider = (b['service_provider_email'] ?? '').toString().trim();
    final status = (b['status'] ?? 'pending').toString();
    final statusClr = _statusColor(status);
    final timeLabel = _timeLabel(b);

    final last = _lastMsg[bookingId];
    final lastBody = (last?['body'] ?? '').toString();
    final lastSender = (last?['sender'] ?? '').toString();
    final lastAtStr = (last?['created_at'] ?? '').toString();
    DateTime? lastWhen;
    try {
      lastWhen = DateTime.parse(lastAtStr).toLocal();
    } catch (_) {}
    final msgCount = _msgCount[bookingId] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border(
          left: BorderSide(color: statusClr.withOpacity(.85), width: 4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Icon + title + status
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: statusClr.withOpacity(.12),
                    shape: BoxShape.circle,
                  ),
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  child: Icon(Icons.event, color: statusClr),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    petName.isNotEmpty ? petName : 'Booking',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusClr,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Time
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(timeLabel, style: const TextStyle(color: Colors.black87)),
              ],
            ),

            const SizedBox(height: 4),

            // Provider
            if (provider.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.medical_services_outlined,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      provider,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],

            // Owner
            if (ownerName.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(ownerName,
                      style: const TextStyle(color: Colors.black87)),
                ],
              ),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Messages preview row
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _openMessagesSheet(bookingId),
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.chat_bubble_outline,
                            color: Color(0xFF842EAC)),
                        if (msgCount > 0)
                          Positioned(
                            right: -8,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF842EAC),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$msgCount',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: last == null
                          ? const Text(
                        'No messages yet. Tap to start a conversation.',
                        style: TextStyle(color: Colors.black54),
                      )
                          : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${lastSender == "owner" ? "You" : "Provider"}: $lastBody',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                          if (lastWhen != null)
                            Text(
                              _relative(lastWhen),
                              style: const TextStyle(
                                  color: Colors.black45, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: Colors.black45),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Messaging Sheet (Owner) ─────────────────────────

class _MessageSheetOwner extends StatefulWidget {
  const _MessageSheetOwner({
    required this.bookingId,
    required this.onSummary,
  });

  final String bookingId;
  final void Function(Map<String, dynamic> last, int count) onSummary;

  @override
  State<_MessageSheetOwner> createState() => _MessageSheetOwnerState();
}

class _MessageSheetOwnerState extends State<_MessageSheetOwner>
    with WidgetsBindingObserver {
  static const Color kPrimary = Color(0xFF842EAC);

  final supabase = Supabase.instance.client;
  final _text = TextEditingController();
  final _scroll = ScrollController();

  List<Map<String, dynamic>> _msgs = [];
  final Set<String> _seen = {};
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

  // keep scrolled when keyboard toggles
  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _load() async {
    final rows = await supabase
        .from('messages')
        .select()
        .eq('booking_id', widget.bookingId)
        .order('created_at', ascending: true);

    final list =
    (rows as List).map((e) => Map<String, dynamic>.from(e)).toList();
    for (final m in list) {
      _seen.add(_key(m));
    }

    setState(() => _msgs = list);
    _scrollToBottom();
    _updateSummary();
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
        if (_seen.contains(k)) return;
        _seen.add(k);
        setState(() => _msgs.add(m));
        _scrollToBottom();
        _updateSummary();
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

  void _updateSummary() {
    if (_msgs.isEmpty) return;
    final last = _msgs.last;
    widget.onSummary({
      'booking_id': widget.bookingId,
      'sender': last['sender'],
      'body': last['body'],
      'created_at': last['created_at'],
    }, _msgs.length);
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    if (body.isEmpty) return;

    final nowIso = DateTime.now().toUtc().toIso8601String();
    final optimistic = {
      'booking_id': widget.bookingId,
      'sender': 'owner', // this screen is for pet owners
      'body': body,
      'created_at': nowIso,
    };

    final k = _key(optimistic);
    _seen.add(k);
    setState(() {
      _msgs.add(optimistic);
      _text.clear();
    });
    _scrollToBottom();
    _updateSummary();

    try {
      await supabase.from('messages').insert(optimistic);
    } catch (e) {
      setState(() => _msgs.removeWhere((m) => _key(m) == k));
      _updateSummary();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  String _formatTime(dynamic createdAt) {
    try {
      final dt = DateTime.parse(createdAt as String).toLocal();
      return DateFormat('MMM d • h:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.12),
                  blurRadius: 18,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Messages',
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Divider(height: 1),

                // Messages
                Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    itemCount: _msgs.length,
                    itemBuilder: (_, i) {
                      final m = _msgs[i];
                      final mine = (m['sender'] ?? '') == 'owner';
                      final when = _formatTime(m['created_at']);
                      return Align(
                        alignment: mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          constraints: const BoxConstraints(maxWidth: 300),
                          decoration: BoxDecoration(
                            color: mine
                                ? kPrimary
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: mine
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                (m['body'] ?? '').toString(),
                                style: TextStyle(
                                  color: mine ? Colors.white : Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                when,
                                style: TextStyle(
                                  color:
                                  mine ? Colors.white70 : Colors.black54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Composer
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _text,
                            minLines: 1,
                            maxLines: 4,
                            onTap: _scrollToBottom,
                            decoration: InputDecoration(
                              hintText: 'Type a message…',
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                BorderSide(color: Colors.grey.shade300),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: kPrimary, width: 1.4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: _send,
                            icon: const Icon(Icons.send, size: 18),
                            label: const Text('Send'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
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
}

// ───────────────────────── Sub-widgets ─────────────────────────

class _FilterBar extends StatelessWidget {
  final _Filter value;
  final ValueChanged<_Filter> onChanged;
  const _FilterBar({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const chipStyle = TextStyle(fontWeight: FontWeight.w600);
    final entries = const [
      (_Filter.upcoming, 'Upcoming'),
      (_Filter.past, 'Past'),
      (_Filter.pending, 'Pending'),
      (_Filter.confirmed, 'Confirmed'),
      (_Filter.cancelled, 'Cancelled'),
      (_Filter.all, 'All'),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (val, label) = entries[i];
          final selected = value == val;
          return ChoiceChip(
            label: Text(label, style: chipStyle),
            selected: selected,
            selectedColor: const Color(0xFF842EAC).withOpacity(.15),
            onSelected: (_) => onChanged(val),
            shape: StadiumBorder(
              side: BorderSide(
                color: selected
                    ? const Color(0xFF842EAC)
                    : Colors.grey.shade300,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRetry;
  const _EmptyState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No bookings yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text(
              'When you book a service, it will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: const [
        SizedBox(height: 24),
        Icon(Icons.search_off, size: 56, color: Colors.grey),
        SizedBox(height: 12),
        Text(
          'No results for this filter',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 6),
        Text(
          'Try a different filter or pull to refresh.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      ],
    );
  }
}
