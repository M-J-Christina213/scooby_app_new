// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unused_import, unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scooby_app_new/models/pet.dart';
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

// Small helpers
DateTime combine(DateTime d, TimeOfDay t) =>
    DateTime(d.year, d.month, d.day, t.hour, t.minute);

class _HomeScreenState extends State<HomeScreen> {
  final ServiceProviderService _service = ServiceProviderService();
  final _sb = Supabase.instance.client;

  int _selectedIndex = 0;
  String _selectedRole = 'Veterinarian';
  List<ServiceProvider> nearbyProviders = [];
  List<ServiceProvider> recommendedProviders = [];
  bool loading = true;
  bool hasPets = false;

  // Walk schedule state
  DateTime? _nextWalkStart;
  DateTime? _nextWalkEnd;
  bool _isInWalkWindow = false;
  bool _loadingWalk = false;
  DateTime? _lastWalkUpdate; // Track last update time

  // Pet names for walk windows
  String? _currentWalkPet;
  String? _nextWalkPet;

  // Notifications state
  List<Map<String, dynamic>> _notifs = [];
  int _unreadCount = 0;
  bool _loadingNotifs = false;

  // Track dismissals
  final Set<String> _dismissedLocalNotifs = <String>{};
  final Set<String> _dismissedReminderNotifs = <String>{};

  // cache pet_owner id
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
        onGoToMyPets: () => setState(() => _selectedIndex = 1),
      ),
      ProfileScreen(
        onGoToMyPets: () => setState(() => _selectedIndex = 1),
      ),
    ];

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _ensureOwnerId();
    await _loadData();
    await _refreshHasPets();
    await _loadWalkInfo();
    await _loadNotifications();
  }

  Future<void> _refreshHasPets() async {
    if (currentUserId.isEmpty) {
      setState(() => hasPets = false);
      return;
    }
    try {
      final pets = await PetService.instance.fetchPetsForUser(currentUserId);
      if (!mounted) return;
      setState(() => hasPets = pets.isNotEmpty);
    } catch (_) {
      if (!mounted) return;
      setState(() => hasPets = false);
    }
  }

  Future<void> _loadData() async {
    setState(() => loading = true);
    try {
      final nearby = await _service.fetchServiceProvidersByCityAndRole(
        widget.userCity,
        _selectedRole,
      );
      final recommended = sampleRecommendedProviders;

      if (!mounted) return;
      setState(() {
        nearbyProviders = nearby;
        recommendedProviders = recommended;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        nearbyProviders = [];
        recommendedProviders = [];
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loadWalkInfo() async {
    if (currentUserId.isEmpty) return;
    final now = DateTime.now();
    if (_lastWalkUpdate != null &&
        now.difference(_lastWalkUpdate!).inSeconds < 30) {
      return;
    }

    setState(() => _loadingWalk = true);

    try {
      final res = await PetService.instance.getWalkWindowForUser(currentUserId);
      if (!mounted) return;
      setState(() {
        _isInWalkWindow = res.isInWindow;
        _nextWalkStart = res.isInWindow ? res.currentStart : res.nextStart;
        _nextWalkEnd = res.isInWindow ? res.currentEnd : res.nextEnd;
        _currentWalkPet = res.currentPetName;
        _nextWalkPet = res.nextPetName;
        _loadingWalk = false;
        _lastWalkUpdate = now;
      });
      _mergeWalkVirtualIntoNotifs();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInWalkWindow = false;
        _nextWalkStart = null;
        _nextWalkEnd = null;
        _currentWalkPet = null;
        _nextWalkPet = null;
        _loadingWalk = false;
        _lastWalkUpdate = now;
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

  

Future<void> _loadNotifications({bool testing = false}) async {

  
  if (currentUserId.isEmpty) return;

  setState(() => _loadingNotifs = true);

  final List<Map<String, dynamic>> list = [];
  final now = DateTime.now();

  try {
    final ownerId = await _ensureOwnerId();
    if (ownerId == null) return;

    // ────────────── Fetch all pets once ──────────────
    final pets = await PetService.instance.fetchPetsForUser(currentUserId);

    // ────────────── Booking notifications ──────────────
    final bookings =
        await BookingController().getUserBookingsNeedingNotification(ownerId);

    // fetch all pets in parallel
    final petMap = {for (var pet in pets) pet.id: pet};

    for (final b in bookings) {
      final pet = petMap[b.petId];
      if (pet != null) {
        final dateStr = DateFormat('EEE, MMM d').format(b.date);
        list.add({
          'id': b.id,
          'type': 'booking',
          'title': '📅 Booking ${b.status}',
          'body': 'For ${pet.name} • $dateStr at ${b.time}',
          'created_at': b.createdAt.toIso8601String(),
          'is_read': false,
          'local': false,
        });
      }
    }

    // ────────────── Birthday, Meals & Health ──────────────
    for (final pet in pets) {
      final dob = testing ? now : (pet.createdAt ?? now);
      final allergies = testing ? "Test Allergy" : (pet.allergies ?? "none");

      // Meal times
      final meals = {
        'Breakfast': testing ? "07:00" : (pet.breakfastTime ?? "07:00"),
        'Lunch': testing ? "13:00" : (pet.lunchTime ?? "13:00"),
        'Snack': testing ? "16:00" : (pet.snackTime ?? "16:00"),
        'Dinner': testing ? "20:00" : (pet.dinnerTime ?? "20:00"),
      };

      // Birthday
      final nextBday = DateTime(now.year, dob.month, dob.day).isBefore(now)
          ? DateTime(now.year + 1, dob.month, dob.day)
          : DateTime(now.year, dob.month, dob.day);

      final daysLeft = nextBday.difference(now).inDays;
      String? bdayMsg;
      if (testing || daysLeft == 30) {
        bdayMsg = "🎂 ${pet.name}'s birthday is in one month!";
      } else if (daysLeft == 14) {
        bdayMsg = "🐾 Two weeks to ${pet.name}'s birthday!";
      } else if (daysLeft == 7) {
        bdayMsg = "⏳ ${pet.name}'s birthday is in a week!";
      } else if (daysLeft == 0) {
        bdayMsg = "🎉 Happy Birthday ${pet.name}!";
      }
      if (bdayMsg != null) {
        list.add({
          'id': 'birthday-${pet.id}',
          'type': 'birthday',
          'title': '🎂 Birthday Reminder',
          'body': bdayMsg,
          'created_at': now.toIso8601String(),
          'is_read': false,
          'local': true,
        });
      }

        DateTime combineDateAndTime(DateTime date, String hhmm) {
        final parts = hhmm.split(':');
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        return DateTime(date.year, date.month, date.day, h, m);
      }

      // Meals
      meals.forEach((mealName, timeStr) {
        final mealTime = combineDateAndTime(now, timeStr);
        if (testing ||
            (now.isAfter(mealTime.subtract(const Duration(minutes: 15))) &&
                now.isBefore(mealTime.add(const Duration(minutes: 15))))) {
          list.add({
            'id': 'meal-${pet.id}-$mealName',
            'type': 'meal',
            'title': '🍽 $mealName Time',
            'body': "Time to feed ${pet.name}! Allergies: $allergies",
            'created_at': now.toIso8601String(),
            'is_read': false,
            'local': true,
          });
        }
      });

      // Health reminders (fake testing dates)
      final healthDue = <String, DateTime>{
        'Vaccination': testing ? now : (pet.vaccinationDate ?? now),
        'Medical Checkup': testing ? now : (pet.medicalCheckupDate ?? now),
        'Prescription Renewal': testing ? now : (pet.prescriptionDate ?? now),
      };

      healthDue.forEach((key, date) {
        final diffDays = date.difference(now).inDays;
        if (testing || (diffDays <= 7 && diffDays >= 0)) {
          list.add({
            'id': 'health-${pet.id}-$key',
            'type': 'health',
            'title': '💊 $key Reminder',
            'body':
                "Hey! ${pet.name} might need $key soon. Keep up the great care! 🐾",
            'created_at': now.toIso8601String(),
            'is_read': false,
            'local': true,
          });
        }
      });
    }

    setState(() {
      _notifs = list;
      _loadingNotifs = false;
    });
  } catch (e) {
    debugPrint('Error loading notifications: $e');
    setState(() => _loadingNotifs = false);
  }

  
}



  //END of notfications load

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
          providers: nearbyProviders,
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
                'Next walk: $who${_fmtDateTime(_nextWalkStart!)}',
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
      builder: (_) => StatefulBuilder(
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
                              await _loadNotifications(testing:true);
                              modalSetState(() {});
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
                                      modalSetState(() {});
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
    
    return loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
      onRefresh: () async {
        await _loadData();
        // ADDED: Only refresh walk info if it's been more than 30 seconds
        if (_lastWalkUpdate == null || 
            DateTime.now().difference(_lastWalkUpdate!).inSeconds > 30) {
          await _loadWalkInfo();
        }
        await _loadNotifications();
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
                'Nearby $_selectedRole\'',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              if (nearbyProviders.length > 4)
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

          nearbyProviders.isEmpty
              ? const Text('No nearby providers found.')
              : SizedBox(
            height: 260,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: nearbyProviders.length > 4
                  ? 4
                  : nearbyProviders.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final provider = nearbyProviders[index];
                return ServiceProviderCard(
                  provider: provider,
                  onTap: () => _handleProviderTap(provider),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Recommended
         Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recommended $_selectedRole\'',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              if (nearbyProviders.length > 4)
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

          nearbyProviders.isEmpty
              ? const Text('No recommended providers found.')
              : SizedBox(
            height: 260,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: nearbyProviders.length > 4
                  ? 4
                  : nearbyProviders.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final provider = nearbyProviders[index];
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
  DateTime? combineDateAndTime(DateTime date, String timeStr) {
    final TimeOfDay? tod = _parseTimeFlexible(timeStr);
    if (tod == null) return null;
    return DateTime(date.year, date.month, date.day, tod.hour, tod.minute);
  }

  TimeOfDay? _parseTimeFlexible(String? raw) {
    if (raw == null) return null;
    String s = raw.trim().toUpperCase();

    final m24 = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?').firstMatch(s);
    if (m24 != null) {
      final h = int.tryParse(m24.group(1)!);
      final m = int.tryParse(m24.group(2)!);
      if (h != null && m != null && h >= 0 && h < 24 && m >= 0 && m < 60) {
        return TimeOfDay(hour: h, minute: m);
      }
    }

    final m12 = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)').firstMatch(s);
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
                  ? Image.network(
                      provider.profileImageUrl,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
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

  

