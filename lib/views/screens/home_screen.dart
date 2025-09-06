// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scooby_app_new/views/screens/login_screen.dart';
import 'package:scooby_app_new/views/screens/sample_recommended_providers.dart';
import 'package:scooby_app_new/views/screens/service_detail_screen.dart';
import 'package:scooby_app_new/controllers/service_provider_service.dart';
import 'package:scooby_app_new/models/service_provider.dart';
import 'package:scooby_app_new/views/screens/bookings_screen.dart';
import 'package:scooby_app_new/views/screens/my_pets_screen.dart';
import 'package:scooby_app_new/views/screens/profile_screen.dart';
import 'package:scooby_app_new/views/screens/nearby_services_screen.dart';
import 'package:scooby_app_new/widgets/bottom_nav.dart';
import 'package:scooby_app_new/controllers/pet_service.dart';

// NEW: bookings
import 'package:scooby_app_new/controllers/booking_controller.dart';
import 'package:scooby_app_new/models/booking_model.dart';

class HomeScreen extends StatefulWidget {
  final String userCity;
  final String userId;

  const HomeScreen({
    super.key,
    required this.userCity,
    required this.userId,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// ─────────────────────────────────────────────────────────────────────────────
// Small helpers

DateTime _combine(DateTime d, TimeOfDay t) =>
    DateTime(d.year, d.month, d.day, t.hour, t.minute);

// ─────────────────────────────────────────────────────────────────────────────

class _HomeScreenState extends State<HomeScreen> {
  final ServiceProviderService _service = ServiceProviderService();
  final _sb = Supabase.instance.client;

  int _selectedIndex = 0;
  String _selectedRole = 'Veterinarian';
  List<ServiceProvider> _nearbyProviders = [];
  List<ServiceProvider> _recommendedProviders = [];
  bool _loading = true;
  bool _hasPets = false;

  // Walk schedule state
  DateTime? _nextWalkStart;
  DateTime? _nextWalkEnd;
  bool _isInWalkWindow = false;
  bool _loadingWalk = false;

  // NEW: pet names for walk windows
  String? _currentWalkPet;
  String? _nextWalkPet;

  // Notifications state
  List<Map<String, dynamic>> _notifs = [];
  int _unreadCount = 0;
  bool _loadingNotifs = false;

  // Track dismissals of local (virtual) notifications so they don't reappear
  final Set<String> _dismissedLocalNotifs = <String>{};         // walk-only local ids
  final Set<String> _dismissedReminderNotifs = <String>{};      // reminder_<bookingId>

  // cache pet_owner id for bookings lookup
  String? _ownerId;

  late String currentUserId;
  late List<Widget> _tabsWithoutHome;

  final List<Map<String, String>> _serviceTypes = const [
    {'title': 'Veterinarian', 'image': 'assets/images/vet.png'},
    {'title': 'Pet Groomer', 'image': 'assets/images/groomer.png'},
    {'title': 'Pet Sitter', 'image': 'assets/images/sitter.webp'},
  ];

  final List<String> _petTips = const [
    'Make sure your pet drinks enough water.',
    'Regular grooming keeps your pet healthy.',
    'Daily walks help your pet stay active.',
    'Vaccinate your pets on time.',
    'Healthy diet leads to happy pets.',
  ];

  @override
  void initState() {
    super.initState();

    currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

    _tabsWithoutHome = [
      MyPetsScreen(userId: currentUserId),
      BookingsScreen(),
      ProfileScreen(
        onGoToMyPets: () => setState(() => _selectedIndex = 1), // ← NEW
      ),
    ];

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _ensureOwnerId();
    _loadData();
    _refreshHasPets();
    _loadWalkInfo();
    _loadNotifications();
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Data loads

  Future<void> _refreshHasPets() async {
    if (currentUserId.isEmpty) {
      setState(() => _hasPets = false);
      return;
    }
    try {
      final pets = await PetService.instance.fetchPetsForUser(currentUserId);
      if (!mounted) return;
      setState(() => _hasPets = pets.isNotEmpty);
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasPets = false);
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final nearby = await _service.fetchServiceProvidersByCityAndRole(
        widget.userCity,
        _selectedRole,
      );
      final recommended = sampleRecommendedProviders;

      setState(() {
        _nearbyProviders = nearby;
        _recommendedProviders = recommended;
      });

      await _refreshHasPets();
      await _loadWalkInfo();
      await _loadNotifications();
    } catch (_) {
      _nearbyProviders = [];
      _recommendedProviders = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadWalkInfo() async {
    if (currentUserId.isEmpty) return;
    setState(() => _loadingWalk = true);

    try {
      final res = await PetService.instance.getWalkWindowForUser(currentUserId);

      if (!mounted) return;
      setState(() {
        _isInWalkWindow = res.isInWindow;
        _nextWalkStart = res.isInWindow ? res.currentStart : res.nextStart;
        _nextWalkEnd   = res.isInWindow ? res.currentEnd   : res.nextEnd;

        // NEW: pet names
        _currentWalkPet = res.currentPetName;
        _nextWalkPet    = res.nextPetName;

        _loadingWalk = false;
      });

      // Reflect the walk status in notifications immediately
      _mergeWalkVirtualIntoNotifs();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInWalkWindow = false;
        _nextWalkStart = null;
        _nextWalkEnd = null;
        _currentWalkPet = null; // NEW
        _nextWalkPet = null;    // NEW
        _loadingWalk = false;
      });
      _mergeWalkVirtualIntoNotifs();
    }
  }

  Future<String?> _ensureOwnerId() async {
    if (_ownerId != null || currentUserId.isEmpty) return _ownerId;
    try {
      final row = await _sb
          .from('pet_owners')
          .select('id')
          .eq('user_id', currentUserId)
          .maybeSingle();
      _ownerId = row?['id'] as String?;
    } catch (_) {
      _ownerId = null;
    }
    return _ownerId;
  }

  // Unified: bookings + optional DB notifs table + virtual walk + upcoming reminders
  Future<void> _loadNotifications() async {
    if (currentUserId.isEmpty) return;
    setState(() => _loadingNotifs = true);

    final List<Map<String, dynamic>> list = [];

    // 1) Booking notifications (status != pending, notofication_status == false)
    try {
      final ownerId = await _ensureOwnerId();
      if (ownerId != null) {
        final bookings = await BookingController()
            .getUserBookingsNeedingNotification(ownerId);

        for (final Booking b in bookings) {
          final dateStr = DateFormat('EEE, MMM d').format(b.date);
          final title = 'Booking ${b.status}';
          final body = 'For ${b.petName} • $dateStr at ${b.time}';
          list.add({
            'id': b.id,
            'type': 'booking',
            'title': title,
            'body': body,
            'created_at': b.createdAt.toIso8601String(),
            'is_read': false,
            'local': false,
          });
        }

        // 1b) Upcoming booking reminders (within 24h by default)
        final upcoming =
        await BookingController().getUpcomingBookings(ownerId, withinHours: 24);
        for (final Booking b in upcoming) {
          final reminderId = 'reminder_${b.id}';
          if (_dismissedReminderNotifs.contains(reminderId)) continue;

          final dt = _combineDateAndTime(b.date, b.time);
          final whenText = (dt != null)
              ? '${DateFormat('EEE, MMM d').format(dt)} at ${DateFormat('h:mm a').format(dt)}'
              : '${DateFormat('EEE, MMM d').format(b.date)} at ${b.time}';

          list.add({
            'id': reminderId,
            'type': 'reminder',
            'title': 'Upcoming booking',
            'body': 'For ${b.petName} • $whenText',
            'created_at': DateTime.now().toIso8601String(),
            'reminder_at': (dt ?? b.date).toIso8601String(),
            'is_read': false,
            'local': true,
          });
        }
      }
    } catch (_) {
      // ignore
    }

    // 2) Optional: include rows from a notifications table if you use it
    try {
      final rows = await _sb
          .from('notifications')
          .select('id, title, body, created_at, is_read')
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false)
          .limit(50);

      final dbList = (rows as List).map<Map<String, dynamic>>((r) {
        return {
          'id': r['id'],
          'type': 'db',
          'title': r['title'] ?? 'Notification',
          'body': r['body'] ?? '',
          'created_at': r['created_at'],
          'is_read': r['is_read'] ?? false,
          'local': false,
        };
      }).toList();

      list.addAll(dbList);
    } catch (_) {
      // ignore
    }

    // 3) Add the virtual walk notification (top candidate)
    final virtual = _buildWalkVirtualNotif();
    if (virtual != null &&
        !_dismissedLocalNotifs.contains(virtual['id'] as String)) {
      list.add(virtual);
    }

    // Sort
    int priority(Map n) {
      switch (n['type']) {
        case 'walk': return 3;
        case 'reminder': return 2;
        case 'booking': return 1;
        default: return 0;
      }
    }

    DateTime _ts(Map n) {
      if (n['type'] == 'reminder' && n['reminder_at'] is String) {
        return DateTime.tryParse(n['reminder_at'] as String) ??
            DateTime.fromMillisecondsSinceEpoch(0);
      }
      if (n['created_at'] is String) {
        return DateTime.tryParse(n['created_at'] as String) ??
            DateTime.fromMillisecondsSinceEpoch(0);
      }
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    list.sort((a, b) {
      final pa = priority(a), pb = priority(b);
      if (pa != pb) return pb.compareTo(pa);
      if (a['type'] == 'reminder' && b['type'] == 'reminder') {
        return _ts(a).compareTo(_ts(b)); // earlier first
      }
      return _ts(b).compareTo(_ts(a));   // newer first
    });

    if (!mounted) return;
    setState(() {
      _notifs = list;
      _unreadCount =
          _notifs.where((n) => (n['is_read'] as bool?) == false).length;
      _loadingNotifs = false;
    });
  }

  // Build a virtual notification from the current walk status
  Map<String, dynamic>? _buildWalkVirtualNotif() {
    if (_isInWalkWindow && _nextWalkEnd != null) {
      final who = _currentWalkPet?.isNotEmpty == true ? ' (${_currentWalkPet!})' : '';
      return {
        'id': 'walk_now',
        'type': 'walk',
        'title': 'Time to walk 🐾$who',
        'body': 'Window active until ${_fmtTime(_nextWalkEnd!)}.',
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
        'local': true,
      };
    }
    if (_nextWalkStart != null) {
      final who = _nextWalkPet?.isNotEmpty == true ? ' (${_nextWalkPet!})' : '';
      return {
        'id': 'walk_next',
        'type': 'walk',
        'title': 'Next walk 🐾$who',
        'body': 'Scheduled at ${_fmtDateTime(_nextWalkStart!)}.',
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
        'local': true,
      };
    }
    return null;
  }

  // Merge/refresh the virtual walk notification into the current _notifs list
  void _mergeWalkVirtualIntoNotifs() {
    final local = _buildWalkVirtualNotif();
    setState(() {
      _notifs.removeWhere((n) =>
      (n['id'] == 'walk_now' || n['id'] == 'walk_next') && (n['local'] == true));

      if (local != null && !_dismissedLocalNotifs.contains(local['id'] as String)) {
        _notifs.insert(0, local);
      }
      _unreadCount =
          _notifs.where((n) => (n['is_read'] as bool?) == false).length;
    });
  }

  Future<void> _dismissNotification(dynamic id) async {
    final item = _notifs.firstWhere((n) => n['id'] == id, orElse: () => const {});
    final String type = (item['type'] ?? '') as String;

    if (type == 'booking') {
      try { await BookingController().markBookingNotificationTrue(id as String); } catch (_) {}
    } else if (type == 'db') {
      try { await _sb.from('notifications').update({'is_read': true}).eq('id', id); } catch (_) {}
    } else if (type == 'walk') {
      _dismissedLocalNotifs.add(id as String);
    } else if (type == 'reminder') {
      _dismissedReminderNotifs.add(id as String);
    }

    setState(() {
      _notifs.removeWhere((n) => n['id'] == id);
      _unreadCount =
          _notifs.where((n) => (n['is_read'] as bool?) == false).length;
    });
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Guards & navigation

  void _promptRegisterPet() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('You have no pets registered. Please register a pet first.'),
        action: SnackBarAction(
          label: 'Add Pet',
          onPressed: () => setState(() => _selectedIndex = 1),
        ),
      ),
    );
  }

  Future<bool> _ensureHasPets() async {
    try {
      final pets = await PetService.instance.fetchPetsForUser(currentUserId);
      if (!mounted) return false;
      if (pets.isEmpty) {
        _promptRegisterPet();
        return false;
      }
      return true;
    } catch (_) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not verify your pets. Please try again.')),
      );
      return false;
    }
  }

  Future<void> _handleProviderTap(ServiceProvider provider) async {
    if (!await _ensureHasPets()) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceDetailScreen(serviceProvider: provider),
      ),
    );
  }

  Future<void> _handleSeeAllTap() async {
    if (!await _ensureHasPets()) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NearbyServicesScreen(
          providers: _nearbyProviders,
          role: _selectedRole,
        ),
      ),
    );
  }

  void _onRoleSelected(String role) {
    if (_selectedRole != role) {
      setState(() => _selectedRole = role);
      _loadData();
    }
  }

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // UI builders

  String _fmtDateTime(DateTime dt) =>
      DateFormat('EEE, MMM d • h:mm a').format(dt);
  String _fmtTime(DateTime dt) => DateFormat('h:mm a').format(dt);

  Widget _walkBadge(Color primary) {
    if (_loadingWalk) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_isInWalkWindow && _nextWalkStart != null && _nextWalkEnd != null) {
      final who = _currentWalkPet?.isNotEmpty == true ? '${_currentWalkPet!} • ' : '';
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(.25),
                blurRadius: 10,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.directions_walk, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Walk now • ${who}until ${_fmtTime(_nextWalkEnd!)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_nextWalkStart != null) {
      final who = _nextWalkPet?.isNotEmpty == true ? '${_nextWalkPet!} • ' : '';
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary, primary.withOpacity(.75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(.2),
                blurRadius: 10,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.schedule, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Next walk: ${who}${_fmtDateTime(_nextWalkStart!)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: const Text('No walk scheduled'),
      ),
    );
  }

  void _openNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder( // <<< IMPORTANT: local state for instant UI updates
        builder: (context, modalSetState) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.85,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            builder: (_, controller) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 24,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Reminders',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Refresh',
                            onPressed: () async {
                              await _loadNotifications();
                              modalSetState(() {}); // refresh list inside sheet
                            },
                            icon: const Icon(Icons.refresh),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _loadingNotifs
                            ? const Center(child: CircularProgressIndicator())
                            : _notifs.isEmpty
                            ? const Center(child: Text('No reminders'))
                            : ListView.builder(
                          controller: controller,
                          itemCount: _notifs.length,
                          itemBuilder: (_, i) {
                            final n = _notifs[i];
                            final created = n['created_at'] as String?;
                            final when = created != null
                                ? DateFormat('MMM d, h:mm a').format(
                                DateTime.parse(created).toLocal())
                                : '';

                            final isWalk = (n['type'] == 'walk');
                            final isBooking = (n['type'] == 'booking');
                            final isReminder = (n['type'] == 'reminder');
                            final leadingIcon = isWalk
                                ? Icons.directions_walk
                                : isReminder
                                ? Icons.alarm
                                : isBooking
                                ? Icons.event_available
                                : Icons.notifications;

                            final Color chipColor = isWalk
                                ? Colors.orange
                                : isReminder
                                ? Colors.blue
                                : isBooking
                                ? Colors.green
                                : const Color(0xFF842EAC);

                            final String chipText = isWalk
                                ? 'Walk'
                                : isReminder
                                ? 'Reminder'
                                : isBooking
                                ? 'Booking'
                                : 'Info';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(.06),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  )
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF842EAC).withOpacity(.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(leadingIcon,
                                        color: const Color(0xFF842EAC)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                n['title'] ?? 'Reminders',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w700),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: chipColor,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                chipText,
                                                style: const TextStyle(
                                                    fontSize: 11, color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          n['body'] ?? '',
                                          style: const TextStyle(color: Colors.black87),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          when,
                                          style: const TextStyle(
                                              color: Colors.grey, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Dismiss',
                                    onPressed: () async {
                                      await _dismissNotification(n['id']);
                                      modalSetState(() {}); // <<< ensure instant removal
                                    },
                                    icon: const Icon(Icons.close),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF842EAC);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? 'Welcome to Scooby'
              : _selectedIndex == 1
              ? 'My Pets'
              : _selectedIndex == 2
              ? 'Bookings'
              : 'Profile',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _confirmLogout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? _buildHomeContent()
          : _tabsWithoutHome[_selectedIndex - 1],
      bottomNavigationBar: BottomNav(
        selectedIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
      floatingActionButton: _selectedIndex == 0
          ? Stack(
        clipBehavior: Clip.none,
        children: [
          FloatingActionButton(
            backgroundColor: primaryColor,
            onPressed: _openNotificationsSheet,
            child: const Icon(Icons.notifications_none),
          ),
          if (_unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Text(
                  _unreadCount > 99 ? '99+' : '$_unreadCount',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _confirmLogout(BuildContext context) async {
    final bool? logout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Do you confirm to logout?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (logout == true) {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Widget _buildHomeContent() {
    const primaryColor = Color(0xFF842EAC);

    return _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
      onRefresh: () async {
        await _loadData();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Top-right next walk badge
          _walkBadge(primaryColor),
          const SizedBox(height: 12),

          // Banner
          Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: const DecorationImage(
                image: AssetImage('assets/images/banner1bg.jpg'),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.12),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            alignment: Alignment.center,
            child: const Text(
              'Caring for your pets, always!',
              style: TextStyle(
                color: Colors.deepPurple,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Service Types
          _buildSectionTitle('Service Types', primaryColor),
          const SizedBox(height: 12),
          _buildServiceTypeList(primaryColor),
          const SizedBox(height: 24),

          // Nearby Services with See All
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nearby $_selectedRole\'s',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              if (_nearbyProviders.length > 4)
                GestureDetector(
                  onTap: _handleSeeAllTap,
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          _nearbyProviders.isEmpty
              ? const Text('No nearby providers found.')
              : SizedBox(
            height: 260,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _nearbyProviders.length > 4
                  ? 4
                  : _nearbyProviders.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final provider = _nearbyProviders[index];
                return ServiceProviderCard(
                  provider: provider,
                  onTap: () => _handleProviderTap(provider),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Recommended
          _buildSectionTitle('Recommended for You', primaryColor),
          const SizedBox(height: 12),
          _recommendedProviders.isEmpty
              ? const Text('No recommendations available.')
              : SizedBox(
            height: 260,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _recommendedProviders.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final provider = _recommendedProviders[index];
                return ServiceProviderCard(
                  provider: provider,
                  onTap: () => _handleProviderTap(provider),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Pet Care Tips
          _buildPetCareTips(primaryColor),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
    );
  }

  Widget _buildServiceTypeList(Color primaryColor) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _serviceTypes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final service = _serviceTypes[index];
          final isSelected = service['title'] == _selectedRole;
          return GestureDetector(
            onTap: () => _onRoleSelected(service['title']!),
            child: Container(
              width: 140,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor.withAlpha(51) : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: primaryColor.withOpacity(.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(service['image']!, height: 80),
                  const SizedBox(height: 12),
                  Text(
                    service['title']!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPetCareTips(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Pet Care Tips', primaryColor),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _petTips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                return Container(
                  width: 250,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.06),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Text(
                    _petTips[index],
                    style: const TextStyle(fontSize: 16),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Combine date + string time to DateTime (for reminders)
  DateTime? _combineDateAndTime(DateTime date, String timeStr) {
    final TimeOfDay? tod = _parseTimeFlexible(timeStr);
    if (tod == null) return null;
    return DateTime(date.year, date.month, date.day, tod.hour, tod.minute);
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
}

// ──────────────────────────────────────────────────────────────────────────────
// Card used in lists
class ServiceProviderCard extends StatelessWidget {
  final ServiceProvider provider;
  final VoidCallback? onTap;

  const ServiceProviderCard({
    super.key,
    required this.provider,
    this.onTap,
  });

  Widget _buildStarRating(double rating) {
    final int fullStars = rating.floor();
    final bool halfStar = (rating - fullStars) >= 0.5;
    return Row(
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return const Icon(Icons.star, color: Colors.amber, size: 16);
        } else if (index == fullStars && halfStar) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 16);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 16);
        }
      }),
    );
  }

  String _getPricingInfo(ServiceProvider p) {
    switch (p.role.toLowerCase()) {
      case 'veterinarian':
        return 'Consultation: ${p.consultationFee.isNotEmpty ? p.consultationFee : "N/A"}';
      case 'pet groomer':
        return 'Price: ${p.pricingDetails.isNotEmpty ? p.pricingDetails : "N/A"}';
      case 'pet sitter':
        return 'Rate: ${p.pricingDetails.isNotEmpty ? p.pricingDetails : "N/A"}';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF842EAC);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: purple.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: provider.profileImageUrl.isNotEmpty
                  ? (provider.profileImageUrl.startsWith('http')
                  ? Image.network(
                provider.profileImageUrl,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
              )
                  : Image.asset(
                provider.profileImageUrl,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
              ))
                  : Container(
                height: 100,
                color: Colors.grey[300],
                child: const Icon(Icons.pets, size: 60, color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.clinicOrSalonName.isNotEmpty
                  ? provider.clinicOrSalonName
                  : provider.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Experience: ${provider.experience} yrs',
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
            const SizedBox(height: 4),
            _buildStarRating(4.5),
            const SizedBox(height: 6),
            Text(
              _getPricingInfo(provider),
              style: const TextStyle(color: purple, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
