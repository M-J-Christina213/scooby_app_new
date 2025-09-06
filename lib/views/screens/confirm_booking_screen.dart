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

  final Color _brand = const Color(0xFF842EAC);

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.preselectedDate;
    _selectedTime = widget.preselectedTime;
    _rangeStartDate = widget.rangeStartDate;
    _rangeEndDate = widget.rangeEndDate;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Helpers: dialogs / time parsing / formatting / validation
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> _showNoticeDialog({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    String primaryText = 'OK',
    VoidCallback? onPrimary,
    String? secondaryText,
    VoidCallback? onSecondary,
  }) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              padding: const EdgeInsets.all(14),
              child: Icon(icon, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            Row(
              children: [
                if (secondaryText != null) ...[
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onSecondary?.call();
                      },
                      child: Text(secondaryText),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onPrimary?.call();
                    },
                    child: Text(primaryText),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Format TimeOfDay to 'HH:mm'
  String _formatTime24(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// Parse stored 'time' like '14:30' or '2:30 PM'
  TimeOfDay? _parseTimeFlexible(String raw) {
    if (raw.isEmpty) return null;
    String s = raw.trim().toUpperCase().replaceAll('.', ':');

    // 24h
    final m24 = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(s);
    if (m24 != null) {
      final h = int.tryParse(m24.group(1)!);
      final min = int.tryParse(m24.group(2)!);
      if (h != null && min != null && h >= 0 && h < 24 && min >= 0 && min < 60) {
        return TimeOfDay(hour: h, minute: min);
      }
    }

    // 12h
    final m12 = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$').firstMatch(s);
    if (m12 != null) {
      int h = int.tryParse(m12.group(1)!) ?? 0;
      final min = int.tryParse(m12.group(2)!) ?? 0;
      final ap = m12.group(3)!; // AM or PM
      if (h == 12) h = 0;       // 12 edge
      if (ap == 'PM') h += 12;
      if (h >= 0 && h < 24 && min >= 0 && min < 60) {
        return TimeOfDay(hour: h, minute: min);
      }
    }
    return null;
  }

  /// Combine date + time
  DateTime _combine(DateTime d, TimeOfDay t) =>
      DateTime(d.year, d.month, d.day, t.hour, t.minute);

  /// Office hours: 08:00–17:00 inclusive
  bool _isWithinOfficeHours(TimeOfDay t) {
    final mins = t.hour * 60 + t.minute;
    return mins >= 8 * 60 && mins <= 17 * 60;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Conflict check: any booking within ±30 minutes for this provider & date?
  // ─────────────────────────────────────────────────────────────────────────────
  Future<bool> _hasTimeConflict({
    required String providerEmail,
    required DateTime date,
    required TimeOfDay time,
  }) async {
    final selectedStart = _combine(date, time);
    final windowStart = selectedStart.subtract(const Duration(minutes: 30));
    final windowEnd = selectedStart.add(const Duration(minutes: 30));

    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final rows = await supabase
        .from('bookings')
        .select('date, time, status')
        .eq('service_provider_email', providerEmail)
        .gte('date', dayStart.toIso8601String())
        .lt('date', dayEnd.toIso8601String())
        .neq('status', 'cancelled')
        .neq('status', 'rejected');

    if (rows is! List) return false;

    for (final r in rows) {
      final String? timeStr = (r['time'] as String?)?.trim();
      final String? dateStr = r['date'] as String?;
      if (timeStr == null || timeStr.isEmpty || dateStr == null) continue;

      final existingDate = DateTime.tryParse(dateStr);
      final existingTod = _parseTimeFlexible(timeStr);
      if (existingDate == null || existingTod == null) continue;

      final existingStart = _combine(existingDate, existingTod);
      final overlaps =
      !(existingStart.isBefore(windowStart) || existingStart.isAfter(windowEnd));

      if (overlaps) return true;
    }
    return false;
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

    // Time-based bookings only (Vet / Groomer)
    if (_selectedDate != null && _selectedTime != null) {
      // 1) Hours validation
      if (!_isWithinOfficeHours(_selectedTime!)) {
        await _showNoticeDialog(
          icon: Icons.access_time_filled_rounded,
          color: Colors.orange,
          title: 'Outside Working Hours',
          message:
          'Please select a time between 8:00 AM and 5:00 PM.\n\n'
              'Selected: ${_selectedTime!.format(context)}',
          primaryText: 'Change Time',
          onPrimary: () {
            // Go back so user can change it on the previous screen
            Navigator.pop(context);
          },
        );
        return;
      }

      // 2) Conflict window check
      final conflict = await _hasTimeConflict(
        providerEmail: widget.serviceProviderEmail,
        date: _selectedDate!,
        time: _selectedTime!,
      );
      if (conflict) {
        await _showNoticeDialog(
          icon: Icons.event_busy_rounded,
          color: Colors.red,
          title: 'Time Unavailable',
          message:
          'That slot overlaps another booking within ±30 minutes.\n'
              'Please choose a different time.',
          primaryText: 'Change Time',
          onPrimary: () {
            Navigator.pop(context); // back to booking screen
          },
        );
        return;
      }
    }

    // Must have at least one pet
    final petService = PetService();
    final pets = await petService.fetchPetsForUser(user.id);
    if (pets.isEmpty) {
      await _showNoticeDialog(
        icon: Icons.pets_rounded,
        color: _brand,
        title: 'No Pets Found',
        message: 'Please add a pet in your profile before booking.',
        primaryText: 'OK',
      );
      return;
    }

    // Pick a pet
    final selectedPetId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    if (selectedPetId == null) return;

    // Owner info
    final extraInfo = await getPetOwnerInfo(user.id);
    final petOwnerName = extraInfo['name'] ?? 'No Name';
    final petOwnerPhone = extraInfo['phone'] ?? 'No Phone';
    final petOwnerEmail = user.email ?? 'No Email';

    // pet_owners.id
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

    // Build row (store time as HH:mm)
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
      'time': _selectedTime != null ? _formatTime24(_selectedTime!) : '00:00',
      'status': 'pending',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      await supabase.from('bookings').insert(bookingData);

      // Success dialog (kept your style)
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          contentPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                padding: const EdgeInsets.all(16),
                child: const Icon(Icons.check, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 16),
              const Text('Booking Request Sent!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // back 1
                  Navigator.pop(context); // back 2
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
      dateText = DateFormat('EEE, MMM d, yyyy').format(_selectedDate!);
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
                backgroundColor: _brand,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirm Booking'),
            ),
          ],
        ),
      ),
    );
  }
}
