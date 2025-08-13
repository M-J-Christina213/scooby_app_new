import 'package:flutter/material.dart';
import 'package:scooby_app_new/views/screens/service_provider_home.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import '../../services/auth_services.dart';

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

    // Listen to changes in authentication state
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      print('Auth event: $event');
      print('Current user: ${session?.user.id ?? 'No user'}');

      if (!mounted) return;

      setState(() {
        _session = session;
      });

      debugPrint("Auth event: $event");
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

    // Not logged in → show login screen
    if (_session == null) {
      return const LoginScreen();
    }

    final userId = _session!.user.id;

    // Logged in → determine role
    return FutureBuilder<String>(
      future: AuthService().getUserRole(userId),
      builder: (context, roleSnapshot) {
        if (roleSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!roleSnapshot.hasData || roleSnapshot.data == null) {
          Supabase.instance.client.auth.signOut();
          return const LoginScreen();
        }

        final role = roleSnapshot.data!;

        if (role == 'service_provider') {
          return FutureBuilder<String?>(
            future: AuthService().getServiceProviderEmail(userId),
            builder: (context, emailSnapshot) {
              if (emailSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (!emailSnapshot.hasData || emailSnapshot.data == null) {
                Supabase.instance.client.auth.signOut();
                return const LoginScreen();
              }

              return ServiceProviderHome(serviceProviderEmail: emailSnapshot.data!);
            },
          );
        }

        if (role == 'pet_owner') {
          return FutureBuilder<String?>(
            future: AuthService().getPetOwnerIdFromAuthId(userId),
            builder: (context, idSnapshot) {
              if (idSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (!idSnapshot.hasData || idSnapshot.data == null) {
                Supabase.instance.client.auth.signOut();
                return const LoginScreen();
              }

              final petOwnerId = idSnapshot.data!;

              return FutureBuilder<String?>(
                future: AuthService().getPetOwnerCityFromAuthId(userId),
                builder: (context, citySnapshot) {
                  if (citySnapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(body: Center(child: CircularProgressIndicator()));
                  }

                  if (!citySnapshot.hasData || citySnapshot.data == null) {
                    Supabase.instance.client.auth.signOut();
                    return const LoginScreen();
                  }

                  return HomeScreen(
                    userId: petOwnerId,
                    userCity: citySnapshot.data!,
                  );
                },
              );
            },
          );
        }

        // Unknown role → sign out
        Supabase.instance.client.auth.signOut();
        return const LoginScreen();
      },
    );
  }
}
