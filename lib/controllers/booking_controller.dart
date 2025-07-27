// booking_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

class BookingController {
  final CollectionReference _bookingCollection =
      FirebaseFirestore.instance.collection('bookings');

  Future<void> addBooking(Booking booking) async {
    await _bookingCollection.add(booking.toMap());
  }
}
