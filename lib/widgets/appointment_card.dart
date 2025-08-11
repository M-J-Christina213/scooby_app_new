import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scooby_app_new/models/booking_model.dart';

class AppointmentCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onView;
  const AppointmentCard({super.key, required this.booking, required this.onView});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Text('${booking.petName.isNotEmpty ? '${booking.petName} • ' : ''}${booking.ownerName}'),
        subtitle: Text('${DateFormat.yMMMd().format(booking.date)} • ${booking.time}'),
        trailing: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: onView),
      ),
    );
  }
}