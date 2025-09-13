// lib/views/screens/service_provider_home.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:scooby_app_new/models/service_provider.dart';
import 'package:scooby_app_new/views/screens/completed_appointments.dart';
import 'package:scooby_app_new/views/screens/login_screen.dart';
import 'package:scooby_app_new/views/screens/pending_appointments.dart';
import 'package:scooby_app_new/views/screens/todays_appointments.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// NEW: profile page tab
import 'package:scooby_app_new/views/screens/service_provider_profile_page.dart';

class ServiceProviderHome extends StatefulWidget {
  final String serviceProviderEmail;

  const ServiceProviderHome({
    super.key,
    required this.serviceProviderEmail,
  });

  @override
  State<ServiceProviderHome> createState() => _ServiceProviderHomeState();
}

class _ServiceProviderHomeState extends State<ServiceProviderHome>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  int _currentIndex = 0;
  ServiceProvider? provider;
  bool loadingProvider = true;

  @override
  void initState() {
    super.initState();
    _fetchProvider();
  }

  Future<void> _fetchProvider() async {
    try {
      final email = widget.serviceProviderEmail.trim();
      if (email.isEmpty) {
        if (!mounted) return;
        setState(() => loadingProvider = false);
        return;
      }

      final resp = await supabase
          .from('service_providers')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        if (resp != null) {
          provider = ServiceProvider.fromMap(resp);
        }
        loadingProvider = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loadingProvider = false);
    }
  }

  void _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  // ————————————————————————————————————————————————————————————————
  // UI bits

  Widget _avatar(String? url, String fallbackName) {
    final initials = (fallbackName.isNotEmpty ? fallbackName[0] : 'S').toUpperCase();
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(url),
      );
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.white.withOpacity(.2),
      child: Text(initials, style: const TextStyle(color: Colors.white)),
    );
  }

  PreferredSizeWidget _modernAppBar() {
    final name = provider?.name ?? 'Service Provider';
    return AppBar(
      elevation: 0,
      toolbarHeight: 64,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7E2CCB), Color(0xFF9C27B0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
          boxShadow: [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            )
          ],
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
      title: Row(
        children: [
          _avatar(provider?.profileImageUrl, name),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Welcome, $name',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _logout,
          icon: const Icon(Icons.logout, color: Colors.white),
          tooltip: 'Logout',
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loadingProvider) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final providerEmail = provider?.email ?? '';
    final providerId = provider?.id ?? '';

    // Pages for NavigationBar
    final pages = <Widget>[
      TodayAppointments(providerEmail: providerEmail, userId: providerId),
      PendingAppointments(providerEmail: providerEmail, userId: providerId),
      UpcomingAppointments(providerEmail: providerEmail, userId: providerId),
      // NEW: Profile tab page
      ServiceProviderProfilePage(serviceProviderEmail: providerEmail),
    ];

    // If your app already has a root MaterialApp, you can return just the Scaffold below.
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF842EAC)),
        navigationBarTheme: NavigationBarThemeData(
          height: 70,
          indicatorColor: const Color(0x22842EAC),
          surfaceTintColor: Colors.white,
          elevation: 3,
          backgroundColor: Colors.white,
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
                (states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? const Color(0xFF842EAC) : Colors.black87,
              );
            },
          ),
        ),
      ),
      home: Scaffold(
        appBar: _modernAppBar(),
        body: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF842EAC).withOpacity(.04),
          ),
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: pages[_currentIndex],
            ),
          ),
        ),

        // MODERN MATERIAL 3 NAVIGATION BAR
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.today_outlined),
              selectedIcon: Icon(Icons.today),
              label: 'Today',
            ),
            NavigationDestination(
              icon: Icon(Icons.hourglass_bottom_outlined),
              selectedIcon: Icon(Icons.hourglass_bottom),
              label: 'Pending',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_outlined),
              selectedIcon: Icon(Icons.event),
              label: 'Appointments',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile', // NEW: profile tab
            ),
          ],
        ),
      ),
    );
  }
}
