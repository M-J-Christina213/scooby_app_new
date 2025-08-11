
import 'package:flutter/material.dart';
import 'package:scooby_app_new/models/service_provider.dart';
import 'package:scooby_app_new/views/screens/completed_appointments.dart';
import 'package:scooby_app_new/views/screens/pending_appointments.dart';
import 'package:scooby_app_new/views/screens/todays_appointments.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceProviderHome extends StatefulWidget {
  const ServiceProviderHome({super.key});

  @override
  State<ServiceProviderHome> createState() => _ServiceProviderHomeState();
}

class _ServiceProviderHomeState extends State<ServiceProviderHome>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  int _currentIndex = 0;
  ServiceProvider? provider;
  bool loadingProvider = true;

  final pages = <Widget>[];

  @override
  void initState() {
    super.initState();
    _fetchProvider();
  }

  Future<void> _fetchProvider() async {
    final email = supabase.auth.currentUser?.email;
    if (email == null) {
      setState(() => loadingProvider = false);
      return;
    }
    final resp = await supabase
        .from('service_providers')
        .select()
        .eq('email', email)
        .maybeSingle();

    if (resp != null) provider = ServiceProvider.fromMap(resp);

    setState(() {
      loadingProvider = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loadingProvider) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // pages depend on role
    final role = provider?.role ?? 'groomer';
    final providerEmail = provider?.email ?? '';

    final pageList = [
      TodayAppointments(providerEmail: providerEmail, role: role),
      PendingAppointments(providerEmail: providerEmail),
      CompletedAppointments(providerEmail: providerEmail),
    ];

    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        primaryColor: Colors.deepPurple,
      ),
      home: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: pageList[_currentIndex],
          transitionBuilder: (child, anim) {
            final slide = Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero)
                .animate(anim);
            return SlideTransition(position: slide, child: FadeTransition(opacity: anim, child: child));
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          selectedItemColor: Colors.deepPurple.shade700,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.pending_actions), label: 'Pending'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Completed'),
          ],
        ),
      ),
    );
  }
}