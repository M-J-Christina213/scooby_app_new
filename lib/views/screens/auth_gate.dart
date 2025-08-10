import 'package:flutter/material.dart';
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
          return FutureBuilder<String?>(
            future: AuthService().getServiceProviderEmail(_session!.user.id),
            builder: (context, emailSnapshot) {
              if (emailSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (emailSnapshot.hasError || emailSnapshot.data == null) {
                Supabase.instance.client.auth.signOut();
                return const LoginScreen();
              }

              final email = emailSnapshot.data!;
              return ConcreteServiceProviderHomeScreen(serviceProviderEmail: email);
            },
          );
        } else if (role == 'pet_owner') {
  return FutureBuilder<String?>(
    future: AuthService().getPetOwnerIdFromAuthId(_session!.user.id),
    builder: (context, idSnapshot) {
      if (idSnapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      if (idSnapshot.hasError || idSnapshot.data == null) {
        Supabase.instance.client.auth.signOut();
        return const LoginScreen();
      }

      final petOwnerId = idSnapshot.data!;

      return FutureBuilder<String?>(
        future: AuthService().getPetOwnerCityFromAuthId(_session!.user.id),
        builder: (context, citySnapshot) {
          if (citySnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (citySnapshot.hasError || citySnapshot.data == null) {
            Supabase.instance.client.auth.signOut();
            return const LoginScreen();
          }

          final petOwnerCity = citySnapshot.data!;

          return HomeScreen(
            userId: petOwnerId,
            userCity: petOwnerCity,
          ); // send correct pet_owners.id
        },
      );
    },
  );
}

 else {
          Supabase.instance.client.auth.signOut();
          return const LoginScreen();
        }
      },
    );
  }
}

class ConcreteServiceProviderHomeScreen extends StatelessWidget {
  final String serviceProviderEmail;

  const ConcreteServiceProviderHomeScreen({super.key, required this.serviceProviderEmail});

  @override
  Widget build(BuildContext context) {
    // Replace with your actual UI for the service provider home screen
    return Scaffold(
      appBar: AppBar(
        title: Text('Service Provider Home'),
      ),
      body: Center(
        child: Text('Welcome, $serviceProviderEmail'),
      ),
    );
  }
}
