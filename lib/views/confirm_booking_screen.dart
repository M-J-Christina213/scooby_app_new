// confirm_booking_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../controllers/booking_controller.dart';
import '../models/booking_model.dart';

class ConfirmBookingScreen extends StatefulWidget {
  final String serviceProviderEmail;  // <-- required parameter

  const ConfirmBookingScreen({super.key, required this.serviceProviderEmail});

  @override
  State<ConfirmBookingScreen> createState() => _ConfirmBookingScreenState();
}

class _ConfirmBookingScreenState extends State<ConfirmBookingScreen> {
  DateTime? _selectedDate;
  String? _selectedTime;

  final List<String> _timeSlots = [
    '09:00 AM', '10:00 AM', '11:00 AM', '12:00 PM',
    '02:00 PM', '03:00 PM', '04:00 PM', '05:00 PM',
  ];

  final BookingController _bookingController = BookingController();

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<Map<String, String?>> getPetOwnerInfo(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('pet_owners').doc(uid).get();
    if (!doc.exists) return {};
    final data = doc.data()!;
    return {
      'name': data['name'] as String?,
      'phone': data['phone'] as String?,
    };
  }

  Future<void> _confirmBooking() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    final extraInfo = await getPetOwnerInfo(user.uid);
    final petOwnerName = extraInfo['name'] ?? 'No Name';
    final petOwnerPhone = extraInfo['phone'] ?? 'No Phone';
    final petOwnerEmail = user.email ?? 'No Email';

    final booking = Booking(
      name: petOwnerName,
      email: petOwnerEmail,
      phone: petOwnerPhone,
      date: _selectedDate!,
      time: _selectedTime!,
      serviceProviderEmail: widget.serviceProviderEmail, // <-- Use passed service provider email here
    );

    try {
      await _bookingController.addBooking(booking);

      final formattedDate = DateFormat('EEE, MMM d, yyyy').format(_selectedDate!);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Booking Confirmed'),
          content: Text('Your booking is confirmed for\n$formattedDate at $_selectedTime'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving booking: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _selectedDate == null
        ? 'Select Date'
        : DateFormat('EEE, MMM d, yyyy').format(_selectedDate!);

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Booking')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(onPressed: _pickDate, child: Text(dateText)),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Select Time',
              ),
              items: _timeSlots
                  .map((time) => DropdownMenuItem(value: time, child: Text(time)))
                  .toList(),
              value: _selectedTime,
              onChanged: (val) => setState(() => _selectedTime = val),
            ),
            const SizedBox(height: 36),
            ElevatedButton(
              onPressed: _confirmBooking,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Confirm Booking'),
            ),
          ],
        ),
      ),
    );
  }
}
