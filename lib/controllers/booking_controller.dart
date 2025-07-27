import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

class BookingController {
  final CollectionReference _bookings =
      FirebaseFirestore.instance.collection('bookings');

  Future<void> addBooking(Booking booking) async {
    await _bookings.add(booking.toMap());
  }
}
