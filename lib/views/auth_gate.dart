import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_screen.dart';
import 'login_screen.dart';
import 'service_provider_home.dart';
import '../services/auth_services.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Session? _session;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialSession();
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      setState(() {
        _session = event.session;
      });
    });
  }

  Future<void> _loadInitialSession() async {
    final currentSession = Supabase.instance.client.auth.currentSession;
    setState(() {
      _session = currentSession;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_session == null) {
      return const LoginScreen();
    }

    return FutureBuilder<String?>(
      future: AuthService().getUserRole(_session!.user.id),
      builder: (context, roleSnapshot) {
        if (roleSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (roleSnapshot.hasError || roleSnapshot.data == null) {
          Supabase.instance.client.auth.signOut();
          return const LoginScreen();
        }

        final role = roleSnapshot.data;
        if (role == 'service_provider') {
          return const ServiceProviderHomeScreen();
        } else if (role == 'pet_owner') {
          return const HomeScreen();
        } else {
          Supabase.instance.client.auth.signOut();
          return const LoginScreen();
        }
      },
    );
  }
}
