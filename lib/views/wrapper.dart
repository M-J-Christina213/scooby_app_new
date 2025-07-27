

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_screen.dart';
import 'login_screen.dart';
import 'service_provider_home.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  Future<String?> getUserRole(String uid) async {
    try {
      final petOwnerDoc = await FirebaseFirestore.instance.collection('pet_owners').doc(uid).get();
      if (petOwnerDoc.exists) return 'pet_owner';

      final serviceProviderDoc = await FirebaseFirestore.instance.collection('service_providers').doc(uid).get();
      if (serviceProviderDoc.exists) return 'service_provider';

      return null; // No role found
    } catch (e) {
   //    log(Error fetching user role: $e);
      return null; // Handle error gracefully
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;

          if (user == null) {
            // Not logged in
            return const LoginScreen();
          } else {
            // Logged in, check role
            return FutureBuilder<String?>(
              future: getUserRole(user.uid),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (roleSnapshot.hasError || roleSnapshot.data == null) {
                  // Role not found or error: Show login
                  FirebaseAuth.instance.signOut(); // Optional: force logout
                  return const LoginScreen();
                }

                final role = roleSnapshot.data;

                if (role == 'service_provider') {
                  return const ServiceProviderHomeScreen();
                } else if (role == 'pet_owner') {
                  return const HomeScreen();
                } else {
                  // Unknown role — fallback
                  FirebaseAuth.instance.signOut();
                  return const LoginScreen();
                }
              },
            );
          }
        }

        // While checking auth state
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
