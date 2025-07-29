import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_screen.dart';
import 'login_screen.dart';
import 'service_provider_home.dart';
import '../services/auth_services.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (session == null) {
          return const LoginScreen();
        } else {
          final user = session.user;
          return FutureBuilder<String?>(
            future: AuthService().getUserRole(user.id),
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
      },
    );
  }
}
