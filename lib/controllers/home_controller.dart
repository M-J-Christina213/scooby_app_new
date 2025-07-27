// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Stream<String> ownerNameStream = FirebaseFirestore.instance
      .collection('pet_owners')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .snapshots()
      .map((doc) => doc.data()?['name'] ?? 'User');

  Future<void> signOut() async {
    await _auth.signOut();
  }

  void showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Confirm Logout'),
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await FirebaseAuth.instance.signOut();
            // No need for Navigator.pushNamed here
          },
          child: const Text('Logout'),
        ),
      ],
    ),
  );
}

  void fetchPetOwnerData() {
    // This can be used for caching or future enhancements
  }
}
