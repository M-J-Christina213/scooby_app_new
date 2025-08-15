import 'package:flutter/material.dart';
import 'package:scooby_app_new/models/service_provider.dart';
import 'package:scooby_app_new/views/screens/completed_appointments.dart';
import 'package:scooby_app_new/views/screens/login_screen.dart';
import 'package:scooby_app_new/views/screens/pending_appointments.dart';
import 'package:scooby_app_new/views/screens/todays_appointments.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    final email = widget.serviceProviderEmail;
    if (email.isEmpty) {
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

  void _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (loadingProvider) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final providerEmail = provider?.email ?? '';

    final pageList = [
      TodayAppointments(providerEmail: providerEmail, userId: provider?.id ?? ''),
      PendingAppointments(providerEmail: providerEmail, userId: provider?.id ?? '',),
      CompletedAppointments(providerEmail: providerEmail, userId: provider?.id ?? ''),
    ];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF842EAC)),
        useMaterial3: true,
        primaryColor: const Color(0xFF842EAC),
        
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF842EAC),
          title: const Text('Welcome to Scooby', style: TextStyle(color: Colors.white)),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _logout,
              
            ),
          ],
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: pageList[_currentIndex],
          transitionBuilder: (child, anim) {
            final slide = Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero)
                .animate(anim);
            return SlideTransition(
                position: slide, child: FadeTransition(opacity: anim, child: child));
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          selectedItemColor: const Color(0xFF842EAC),
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.pending_actions), label: 'Pending'),
            BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Appointments'),
          ],
        ),
      ),
    );
  }
}
