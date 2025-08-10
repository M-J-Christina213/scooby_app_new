import 'package:flutter/material.dart';
import '../../models/service_provider.dart';

class BookingScreen extends StatefulWidget {
  final ServiceProvider provider;
  const BookingScreen({required this.provider, super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? selectedDate;
  String? selectedTimeSlot;
  List<String> timeSlots = [];
  List<String> availableDays = [];

  @override
  void initState() {
    super.initState();

    if (widget.provider.role == 'Veterinarian' || widget.provider.role == 'Pet Groomer') {
      // Simulate some time slots for demo
      timeSlots = ['9:00 AM', '10:30 AM', '12:00 PM', '2:00 PM', '4:00 PM'];
    } else if (widget.provider.role == 'Pet Sitter') {
      // Simulate available days
      availableDays = ['Monday', 'Wednesday', 'Friday', 'Saturday'];
    }
  }

  Future<void> _pickDate() async {
    DateTime today = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        selectedTimeSlot = null; // Reset time slot on date change
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF842EAC);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booking for: ${widget.provider.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),

            // Date picker
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(selectedDate == null ? 'Select Date' : selectedDate!.toLocal().toString().split(' ')[0]),
              onPressed: _pickDate,
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            ),

            const SizedBox(height: 20),

            if (widget.provider.role == 'Veterinarian' || widget.provider.role == 'Pet Groomer') ...[
              Text('Available Time Slots:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              if (selectedDate == null)
                const Text('Please select a date first.')
              else
                Wrap(
                  spacing: 8,
                  children: timeSlots.map((slot) {
                    final isSelected = slot == selectedTimeSlot;
                    return ChoiceChip(
                      label: Text(slot),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          selectedTimeSlot = slot;
                        });
                      },
                      selectedColor: primaryColor,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : null),
                    );
                  }).toList(),
                ),
            ] else if (widget.provider.role == 'Pet Sitter') ...[
              Text('Available Days:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: availableDays.map((day) {
                  final isSelected = selectedDate != null && selectedDate!.weekday == _weekdayFromName(day);
                  return ChoiceChip(
                    label: Text(day),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        // Pick date that matches this weekday
                        DateTime now = DateTime.now();
                        DateTime nextDate = now.add(const Duration(days: 7));
                        for (int i = 0; i < 14; i++) {
                          DateTime check = now.add(Duration(days: i));
                          if (check.weekday == _weekdayFromName(day)) {
                            nextDate = check;
                            break;
                          }
                        }
                        setState(() {
                          selectedDate = nextDate;
                        });
                      } else {
                        setState(() {
                          selectedDate = null;
                        });
                      }
                    },
                    selectedColor: primaryColor,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : null),
                  );
                }).toList(),
              ),
            ],

            const Spacer(),

            Center(
              child: ElevatedButton(
                onPressed: () {
                  
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking confirmation coming soon!')));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: const Text('Confirm Booking', style: TextStyle(fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }

  int _weekdayFromName(String name) {
    switch (name.toLowerCase()) {
      case 'monday':
        return DateTime.monday;
      case 'tuesday':
        return DateTime.tuesday;
      case 'wednesday':
        return DateTime.wednesday;
      case 'thursday':
        return DateTime.thursday;
      case 'friday':
        return DateTime.friday;
      case 'saturday':
        return DateTime.saturday;
      case 'sunday':
        return DateTime.sunday;
      default:
        return 0;
    }
  }
}
