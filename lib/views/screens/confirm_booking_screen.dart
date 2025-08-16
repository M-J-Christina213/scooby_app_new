// confirm_booking_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scooby_app_new/controllers/pet_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConfirmBookingScreen extends StatefulWidget {
  final String serviceProviderEmail;
  final DateTime? preselectedDate;      // nullable for Pet Sitters
  final TimeOfDay? preselectedTime;     // nullable for Pet Sitters
  final DateTime? rangeStartDate;       // for Pet Sitters
  final DateTime? rangeEndDate;         // for Pet Sitters

  const ConfirmBookingScreen({
    super.key,
    required this.serviceProviderEmail,
    this.preselectedDate,
    this.preselectedTime,
    this.rangeStartDate,
    this.rangeEndDate,
  });

  @override
  State<ConfirmBookingScreen> createState() => _ConfirmBookingScreenState();
}

class _ConfirmBookingScreenState extends State<ConfirmBookingScreen> {
  final supabase = Supabase.instance.client;

  late DateTime? _selectedDate;
  late TimeOfDay? _selectedTime;
  late DateTime? _rangeStartDate;
  late DateTime? _rangeEndDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.preselectedDate;
    _selectedTime = widget.preselectedTime;
    _rangeStartDate = widget.rangeStartDate;
    _rangeEndDate = widget.rangeEndDate;
  }

  Future<Map<String, String?>> getPetOwnerInfo(String userId) async {
    final response = await supabase
        .from('pet_owners')
        .select('name, phone_number')
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return {};
    return {
      'name': response['name'] as String?,
      'phone': response['phone_number'] as String?,
    };
  }

  Future<void> _confirmBooking() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('User not logged in')));
      return;
    }

    final petService = PetService();
    final pets = await petService.fetchPetsForUser(user.id);

    if (pets.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('No Pets Found'),
          content: const Text(
              'Please add a pet in your profile before booking.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final selectedPetId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select a Pet'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: pets.length,
            itemBuilder: (context, index) {
              final pet = pets[index];
              return ListTile(
                title: Text(pet.name),
                onTap: () => Navigator.pop(context, pet.id),
              );
            },
          ),
        ),
      ),
    );

    if (selectedPetId == null) return; // user canceled pet selection

    // Get extra owner info
    final extraInfo = await getPetOwnerInfo(user.id);
    final petOwnerName = extraInfo['name'] ?? 'No Name';
    final petOwnerPhone = extraInfo['phone'] ?? 'No Phone';
    final petOwnerEmail = user.email ?? 'No Email';

    // Fetch pet_owners.id
    final petOwnerRow = await supabase
        .from('pet_owners')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();

    if (petOwnerRow == null || petOwnerRow['id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pet owner record not found.')),
      );
      return;
    }

    // Prepare booking data
    final bookingData = {
  'pet_id': selectedPetId,
  'service_provider_email': widget.serviceProviderEmail,
  'owner_id': petOwnerRow['id'],
  'owner_name': petOwnerName,
  'owner_phone': petOwnerPhone,
  'owner_email': petOwnerEmail,
  'date': _selectedDate != null
      ? _selectedDate!.toIso8601String()
      : _rangeStartDate?.toIso8601String(),
  'time': _selectedTime?.format(context) ?? '00:00',  // <-- fallback for Pet Sitters
  'status': 'pending',
  'created_at': DateTime.now().toUtc().toIso8601String(),
};


    try {
      await supabase.from('bookings').insert(bookingData);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          contentPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(16),
                child: const Icon(Icons.check, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'Booking Request Sent!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Thank you for your booking request.\n'
                'Please wait for approval from the service provider.\n'
                'Check "My Bookings" to see the status of your appointment.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Back to previous
                  Navigator.pop(context); // Back to main
                },
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error saving booking: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    String dateText;
    String timeText = '';

    if (_rangeStartDate != null && _rangeEndDate != null) {
      dateText =
          '${DateFormat.yMMMMd().format(_rangeStartDate!)} - ${DateFormat.yMMMMd().format(_rangeEndDate!)}';
    } else if (_selectedDate != null && _selectedTime != null) {
      dateText =
          DateFormat('EEE, MMM d, yyyy').format(_selectedDate!);
      timeText = _selectedTime!.format(context);
    } else {
      dateText = 'No date selected';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Booking')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Date: $dateText', style: const TextStyle(fontSize: 18)),
            if (timeText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Time: $timeText', style: const TextStyle(fontSize: 18)),
            ],
            const SizedBox(height: 36),
            ElevatedButton(
              onPressed: _confirmBooking,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Confirm Booking'),
            ),
          ],
        ),
      ),
    );
  }
}
