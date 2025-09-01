//
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../models/booking_model.dart';
//
// class BookingController {
//   final SupabaseClient _supabase = Supabase.instance.client;
//   static const String _tableName = 'bookings';
//
//   /// Add a booking (uses Booking.toMap which includes notofication_status)
//   Future<void> addBooking(Booking booking) async {
//     try {
//       await _supabase.from(_tableName).insert(booking.toMap());
//     } catch (e) {
//       throw Exception('Failed to add booking: $e');
//     }
//   }
//
//   /// Get bookings that should appear in the notification center:
//   /// - for this owner
//   /// - notofication_status == false
//   /// - status != 'pending'
//   /// newest first
//   Future<List<Booking>> getUserBookingsNeedingNotification(String ownerId) async {
//     try {
//       final res = await _supabase
//           .from(_tableName)
//           .select()
//           .eq('owner_id', ownerId)
//           .eq('notofication_status', false)
//           .neq('status', 'pending')
//           .order('created_at', ascending: false);
//
//       final list = (res as List).cast<Map<String, dynamic>>();
//       return list.map((m) => Booking.fromMap(m)).toList();
//     } catch (e) {
//       throw Exception('Failed to load bookings for notifications: $e');
//     }
//   }
//
//   /// Mark a single booking as "notified" (so it won’t show next time)
//   Future<void> markBookingNotificationTrue(String bookingId) async {
//     try {
//       await _supabase
//           .from(_tableName)
//           .update({'notofication_status': true})
//           .eq('id', bookingId);
//     } catch (e) {
//       throw Exception('Failed to update booking notification status: $e');
//     }
//   }
//
//   /// Optional: mark many bookings as "notified" in one request
//   Future<void> markManyBookingsNotificationTrue(List<String> bookingIds) async {
//     if (bookingIds.isEmpty) return;
//     try {
//       await _supabase
//           .from(_tableName)
//           .update({'notofication_status': true})
//           .in_('id', bookingIds);
//     } catch (e) {
//       throw Exception('Failed to batch update booking notification status: $e');
//     }
//   }
// }

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart'; // for TimeOfDay
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_model.dart';

class BookingController {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'bookings';

  /// Add a booking (Booking.toMap should include `notofication_status`)
  Future<void> addBooking(Booking booking) async {
    try {
      await _supabase.from(_tableName).insert(booking.toMap());
    } catch (e) {
      throw Exception('Failed to add booking: $e');
    }
  }

  /// Bookings for this owner that still need a notification:
  ///  - notofication_status == false
  ///  - status != 'pending'
  Future<List<Booking>> getUserBookingsNeedingNotification(String ownerId) async {
    try {
      final res = await _supabase
          .from(_tableName)
          .select()
          .eq('owner_id', ownerId)
          .eq('notofication_status', false) // keep your column’s spelling
          .neq('status', 'pending')
          .order('created_at', ascending: false);

      final list = (res as List).cast<Map<String, dynamic>>();
      return list.map(Booking.fromMap).toList();
    } catch (e) {
      throw Exception('Failed to load bookings for notifications: $e');
    }
  }

  /// Mark one booking as "notified" so it won’t be fetched next time
  Future<void> markBookingNotificationTrue(String bookingId) async {
    try {
      await _supabase
          .from(_tableName)
          .update({'notofication_status': true})
          .eq('id', bookingId);
    } catch (e) {
      throw Exception('Failed to update booking notification status: $e');
    }
  }

  /// Batch mark many bookings as notified
  Future<void> markManyBookingsNotificationTrue(List<String> bookingIds) async {
    if (bookingIds.isEmpty) return;
    try {
      await _supabase
          .from(_tableName)
          .update({'notofication_status': true})
          .in_('id', bookingIds);
    } catch (e) {
      throw Exception('Failed to batch update booking notification status: $e');
    }
  }

  /// Upcoming bookings within [withinHours] (default 24h).
  /// By default, only considers statuses likely to be actionable.
  Future<List<Booking>> getUpcomingBookings(
      String ownerId, {
        int withinHours = 24,
        List<String> statuses = const ['confirmed', 'accepted'],
      }) async {
    try {
      // Guard: .in_() can error on empty list
      final query = _supabase.from(_tableName).select().eq('owner_id', ownerId);

      if (statuses.isNotEmpty) {
        query.in_('status', statuses);
      }

      final res = await query.order('date', ascending: true);
      final now = DateTime.now();
      final horizon = now.add(Duration(hours: withinHours));

      final result = <Booking>[];
      for (final raw in (res as List)) {
        final b = Booking.fromMap(raw as Map<String, dynamic>);
        final dt = _combineDateAndTime(b.date, b.time);
        if (dt == null) continue;
        if (dt.isAfter(now) && dt.isBefore(horizon)) {
          result.add(b);
        }
      }
      return result;
    } catch (e) {
      throw Exception('Failed to load upcoming bookings: $e');
    }
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  DateTime? _combineDateAndTime(DateTime date, String timeStr) {
    final tod = _parseTimeFlexible(timeStr);
    if (tod == null) return null;
    return DateTime(date.year, date.month, date.day, tod.hour, tod.minute);
  }

  /// Accepts "08:00", "08:00:00", "8:00 AM", "8:00am"
  TimeOfDay? _parseTimeFlexible(String? raw) {
    if (raw == null) return null;
    String s = raw.trim().toUpperCase();

    // 24h HH:mm[:ss]
    final m24 = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?$').firstMatch(s);
    if (m24 != null) {
      final h = int.tryParse(m24.group(1)!);
      final m = int.tryParse(m24.group(2)!);
      if (h != null && m != null && h >= 0 && h < 24 && m >= 0 && m < 60) {
        return TimeOfDay(hour: h, minute: m);
      }
    }

    // 12h h:mm AM/PM
    final m12 = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$').firstMatch(s);
    if (m12 != null) {
      int h = int.tryParse(m12.group(1)!) ?? 0;
      final m = int.tryParse(m12.group(2)!) ?? 0;
      final ap = m12.group(3)!;
      if (h == 12) h = 0;
      if (ap == 'PM') h += 12;
      if (h >= 0 && h < 24 && m >= 0 && m < 60) {
        return TimeOfDay(hour: h, minute: m);
      }
    }
    return null;
  }
}
