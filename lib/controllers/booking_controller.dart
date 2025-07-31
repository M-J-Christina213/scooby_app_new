import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_model.dart';

class BookingController {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _tableName = 'bookings';

  Future<void> addBooking(Booking booking) async {
    final response = await _supabase.from(_tableName).insert(booking.toMap()).execute();

    if (response.error != null) {
      throw Exception('Failed to add booking: ${response.error!.message}');
    }
  }
}

extension on PostgrestResponse {
  get error => null;
}
