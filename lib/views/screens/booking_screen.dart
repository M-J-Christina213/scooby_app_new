import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting date/time
import 'package:scooby_app_new/models/service_provider.dart';
import 'confirm_booking_screen.dart'; // Import ConfirmBookingScreen

class BookingScreen extends StatefulWidget {
  final ServiceProvider serviceProvider;

  const BookingScreen({super.key, required this.serviceProvider});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final Set<String> _selectedServices = {};

  DateTime? _rangeStartDate;
  DateTime? _rangeEndDate;

  Color get primaryColor => const Color(0xFF842EAC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: _buildContentByServiceType(),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ElevatedButton(
            onPressed: _onConfirmBookingPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Confirm Booking', style: TextStyle(fontSize: 18)),
          ),
        ),
      ),
    );
  }

  Widget _buildContentByServiceType() {
    switch (widget.serviceProvider.role) {
      case 'Veterinarian':
        return _buildVetBooking();
      case 'Pet Groomer':
        return _buildGroomerBooking();
      case 'Pet Sitter':
        return _buildPetSitterBooking();
      default:
        return const Text('Service booking not available');
    }
  }

  Widget _buildVetBooking() {
    final consultationFee = widget.serviceProvider.consultationFee;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Appointment Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        _buildBigCalendar(),
        const SizedBox(height: 16),
        const Text('Select Appointment Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        _buildBigTimePicker(),
        const SizedBox(height: 24),
        Text('Consultation Fee:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(
          consultationFee.isNotEmpty ? consultationFee : 'Not specified',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBigCalendar() {
    final now = DateTime.now();
    final firstDate = now;
    final lastDate = DateTime(now.year + 1);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: primaryColor, width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(8),
      child: CalendarDatePicker(
        initialDate: _selectedDate ?? now,
        firstDate: firstDate,
        lastDate: lastDate,
        onDateChanged: (date) {
          setState(() {
            _selectedDate = date;
            _selectedTime = null;
          });
        },
      ),
    );
  }

  Widget _buildBigTimePicker() {
    return GestureDetector(
      onTap: _pickTime,
      child: Container(
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(14),
        ),
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.access_time, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Text(
              _selectedTime == null ? 'Select Time' : _selectedTime!.format(context),
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroomerBooking() {
    final services = widget.serviceProvider.groomingServices;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _datePicker(),
        const SizedBox(height: 8),
        _timePicker(),
        const SizedBox(height: 24),
        const Text('Select Services:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        services.isEmpty
            ? const Text('No grooming services specified.')
            : Wrap(
                spacing: 8,
                children: services.map((service) {
                  final selected = _selectedServices.contains(service);
                  return FilterChip(
                    label: Text(service),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedServices.add(service);
                        } else {
                          _selectedServices.remove(service);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
        const SizedBox(height: 24),
        Text('Pricing Details:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(widget.serviceProvider.pricingDetails.isNotEmpty
            ? widget.serviceProvider.pricingDetails
            : 'Not specified', style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _datePicker() {
    return ListTile(
      title: const Text('Select Date'),
      subtitle: Text(_selectedDate == null ? 'No date chosen' : DateFormat.yMMMMd().format(_selectedDate!)),
      trailing: const Icon(Icons.calendar_today),
      onTap: _pickDate,
    );
  }

  Widget _timePicker() {
    return ListTile(
      title: const Text('Select Time'),
      subtitle: Text(_selectedTime == null ? 'No time chosen' : _selectedTime!.format(context)),
      trailing: const Icon(Icons.access_time),
      onTap: _pickTime,
    );
  }

  Widget _buildPetSitterBooking() {
    final hourlyDailyRate = widget.serviceProvider.rate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Booking Period', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        _buildDateRangePicker(),
        const SizedBox(height: 24),
        Text('Hourly / Daily Rate:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(hourlyDailyRate.isNotEmpty ? hourlyDailyRate : 'Not specified', style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.yellow.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Note: Your address will be shared only with the pet sitter for security and trust reasons.',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangePicker() {
    final displayText = (_rangeStartDate != null && _rangeEndDate != null)
        ? '${DateFormat.yMMMMd().format(_rangeStartDate!)} - ${DateFormat.yMMMMd().format(_rangeEndDate!)}'
        : 'Select date range';

    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDateRangePicker(
          context: context,
          firstDate: now,
          lastDate: DateTime(now.year + 1),
          initialDateRange: _rangeStartDate != null && _rangeEndDate != null
              ? DateTimeRange(start: _rangeStartDate!, end: _rangeEndDate!)
              : null,
        );

        if (picked != null) {
          setState(() {
            _rangeStartDate = picked.start;
            _rangeEndDate = picked.end;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          border: Border.all(color: primaryColor, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(displayText, style: const TextStyle(fontSize: 16)),
            Icon(Icons.date_range, color: primaryColor, size: 28),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _onConfirmBookingPressed() {
    // Validate inputs first
    if (widget.serviceProvider.role == 'Pet Sitter') {
      if (_rangeStartDate == null || _rangeEndDate == null) {
        _showError('Please select a booking period.');
        return;
      }
    } else {
      if (_selectedDate == null) {
        _showError('Please select a date.');
        return;
      }
      if (_selectedTime == null) {
        _showError('Please select a time.');
        return;
      }
    }

    if (widget.serviceProvider.role == 'Pet Groomer' && _selectedServices.isEmpty) {
      _showError('Please select at least one grooming service.');
      return;
    }

    // Navigate to ConfirmBookingScreen and pass date/time info
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmBookingScreen(
          serviceProviderEmail: widget.serviceProvider.email,
          preselectedDate: _selectedDate!,
          preselectedTime: _selectedTime!,
        ),
      ),
    );
  }
}
