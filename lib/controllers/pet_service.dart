// import 'dart:io';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../models/pet.dart';
//
// class PetService {
//   static final PetService instance = PetService();
//   final SupabaseClient supabase = Supabase.instance.client;
//
//   // Fetch pets for a given user
//   Future<List<Pet>> fetchPetsForUser(String userId) async {
//     try {
//       final ownerData = await supabase
//           .from('pet_owners')
//           .select('id')
//           .eq('user_id', userId)
//           .maybeSingle();
//
//       final String? petOwnerId = ownerData != null ? ownerData['id'] as String? : null;
//
//       if (petOwnerId == null) {
//         throw Exception('Pet owner not found for user ID: $userId');
//       }
//
//       final data = await supabase
//           .from('pets')
//           .select()
//           .eq('user_id', petOwnerId)
//           .order('created_at', ascending: false);
//
//       return (data as List<dynamic>)
//           .map((e) => Pet.fromJson(e as Map<String, dynamic>))
//           .toList();
//     } catch (e) {
//       throw Exception('Failed to load pets: $e');
//     }
//   }
//
//   // Upload pet image
//   Future<String?> uploadPetImage(String userId, String filePath, String fileName) async {
//     try {
//       await supabase.storage
//           .from('pet-images')
//           .upload('$userId/$fileName', File(filePath));
//
//       final publicUrl = supabase.storage.from('pet-images').getPublicUrl('$userId/$fileName');
//
//       return publicUrl;
//     } catch (e) {
//       return null;
//     }
//   }
//
//   // Add a new pet
//   Future<void> addPet(Pet pet, String authUserId) async {
//     try {
//       final ownerData = await supabase
//           .from('pet_owners')
//           .select('id')
//           .eq('user_id', authUserId)
//           .maybeSingle();
//
//       final String? petOwnerId = ownerData != null ? ownerData['id'] as String? : null;
//
//       if (petOwnerId == null) {
//         throw Exception('Pet owner not found for user ID: $authUserId');
//       }
//
//       final petJson = pet.toJson(forInsert: true);
//       petJson['user_id'] = petOwnerId;
//
//       await supabase.from('pets').insert([petJson]);
//     } catch (e) {
//       rethrow;
//     }
//   }
//
//   // Update pet details
//   Future<void> updatePet(Pet pet, String authUserId) async {
//     try {
//       final petJson = pet.toJson(forInsert: true);
//
//       // ⚠️ DO NOT overwrite user_id here
//       petJson.remove('user_id');
//
//       await supabase
//           .from('pets')
//           .update(petJson)
//           .eq('id', pet.id);
//     } catch (e) {
//       rethrow;
//     }
//   }
//
//
// }

import 'dart:io';
import 'package:flutter/material.dart'; // for debugPrint
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pet.dart';

class PetService {
  static final PetService instance = PetService();
  final SupabaseClient supabase = Supabase.instance.client;

  // ────────────────────────────────────────────────────────────────────────────
  // Pets CRUD

  /// Fetch pets for a given *auth* user ID (maps to pet_owners.id first).
  Future<List<Pet>> fetchPetsForUser(String userId) async {
    try {
      final ownerData = await supabase
          .from('pet_owners')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      final String? petOwnerId =
      ownerData != null ? ownerData['id'] as String? : null;

      if (petOwnerId == null) {
        throw Exception('Pet owner not found for user ID: $userId');
      }

      final data = await supabase
          .from('pets')
          .select()
          .eq('user_id', petOwnerId)
          .order('created_at', ascending: false);

      return (data as List<dynamic>)
          .map((e) => Pet.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load pets: $e');
    }
  }

  /// Upload pet image to storage and return public URL
  Future<String?> uploadPetImage(
      String userId, String filePath, String fileName) async {
    try {
      await supabase.storage
          .from('pet-images')
          .upload('$userId/$fileName', File(filePath));

      final publicUrl =
      supabase.storage.from('pet-images').getPublicUrl('$userId/$fileName');

      return publicUrl;
    } catch (e) {
      return null;
    }
  }

  /// Add a new pet (maps auth user -> pet_owners.id, stores that in pets.user_id)
  Future<void> addPet(Pet pet, String authUserId) async {
    try {
      final ownerData = await supabase
          .from('pet_owners')
          .select('id')
          .eq('user_id', authUserId)
          .maybeSingle();

      final String? petOwnerId =
      ownerData != null ? ownerData['id'] as String? : null;

      if (petOwnerId == null) {
        throw Exception('Pet owner not found for user ID: $authUserId');
      }

      final petJson = pet.toJson(forInsert: true);
      petJson['user_id'] = petOwnerId; // FK -> pet_owners.id

      await supabase.from('pets').insert([petJson]);
    } catch (e) {
      rethrow;
    }
  }

  /// Update pet details (does NOT overwrite pets.user_id)
  Future<void> updatePet(Pet pet, String authUserId) async {
    try {
      final petJson = pet.toJson(forInsert: true);
      petJson.remove('user_id'); // don't touch FK

      await supabase.from('pets').update(petJson).eq('id', pet.id);
    } catch (e) {
      rethrow;
    }
  }

/// Fetch a single pet by its ID
Future<Pet?> getPetById(String petId) async {
  try {
    final data = await supabase
        .from('pets')
        .select()
        .eq('id', petId)
        .maybeSingle();

    if (data == null) return null;

    return Pet.fromJson(data as Map<String, dynamic>);
  } catch (e) {
    debugPrint('getPetById error: $e');
    return null;
  }
}
  // ────────────────────────────────────────────────────────────────────────────
  // Walking window (matches your schema exactly)

  /// Compute the current or next walking window across all of the user's pets.
  ///
  /// pets table columns used:
  /// - start_walking_time (time without time zone)
  /// - end_walking_time   (time without time zone)
  ///
  /// pets.user_id references pet_owners.id
  Future<WalkWindowResult> getWalkWindowForUser(String authUserId) async {
    try {
      debugPrint('WALK: compute for authUserId=$authUserId');

      // 1) auth user -> pet_owners.id
      final ownerRow = await supabase
          .from('pet_owners')
          .select('id')
          .eq('user_id', authUserId)
          .maybeSingle();

      final ownerId = ownerRow?['id'] as String?;
      if (ownerId == null) {
        debugPrint('WALK: no pet_owners row for auth user');
        return const WalkWindowResult.empty();
      }

      // 2) fetch pets by owner id (FK is stored in pets.user_id)
      final res = await supabase
          .from('pets')
          .select('id, name, start_walking_time, end_walking_time')
          .eq('user_id', ownerId);

      final rows = (res as List)
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList();

      debugPrint('WALK: fetched ${rows.length} pets for owner=$ownerId');
      if (rows.isEmpty) return const WalkWindowResult.empty();

      for (final r in rows) {
        debugPrint(
            'WALK: pet=${r['id']} name=${r['name']} start=${r['start_walking_time']} end=${r['end_walking_time']}');
      }

      final now = DateTime.now();
      final dateBase = DateTime(now.year, now.month, now.day);

      DateTime? curStart, curEnd, nextStart, nextEnd;
      String? curPetName;   // NEW
      String? nextPetName;  // NEW

      for (final r in rows) {
        final startDur = _pgTimeToDuration(r['start_walking_time'] as String?);
        final endDur = _pgTimeToDuration(r['end_walking_time'] as String?);
        if (startDur == null || endDur == null) {
          debugPrint('WALK:   -> times missing for pet=${r['id']}, skipping');
          continue;
        }
        final petName = (r['name'] as String?)?.trim();

        var s = dateBase.add(startDur);
        var e = dateBase.add(endDur);

        // Cross-midnight: e <= s means window passes midnight (e.g., 22:00–06:00)
        if (!e.isAfter(s)) e = e.add(const Duration(days: 1));

        if (now.isAfter(s) && now.isBefore(e)) {
          // active now — prefer the one ending soonest
          if (curEnd == null || e.isBefore(curEnd)) {
            curStart = s;
            curEnd = e;
            curPetName = petName;
          }
          debugPrint(
              'WALK:   -> CURRENT ${s.toIso8601String()} - ${e.toIso8601String()}');
        } else {
          // next candidate: today if in the future else tomorrow
          final candStart = now.isBefore(s) ? s : s.add(const Duration(days: 1));
          final duration = e.difference(s);
          final candEnd = candStart.add(duration);

          if (nextStart == null || candStart.isBefore(nextStart)) {
            nextStart = candStart;
            nextEnd = candEnd;
            nextPetName = petName;
          }
          debugPrint(
              'WALK:   -> NEXT    ${candStart.toIso8601String()} - ${candEnd.toIso8601String()}');
        }
      }

      if (curStart != null && curEnd != null) {
        debugPrint('WALK: RESULT CURRENT $curStart - $curEnd');
        return WalkWindowResult(
          isInWindow: true,
          currentStart: curStart,
          currentEnd: curEnd,
          nextStart: null,
          nextEnd: null,
          currentPetName: curPetName, // NEW
          nextPetName: null,          // NEW
        );
      } else {
        debugPrint('WALK: RESULT NEXT $nextStart - $nextEnd');
        return WalkWindowResult(
          isInWindow: false,
          currentStart: null,
          currentEnd: null,
          nextStart: nextStart,
          nextEnd: nextEnd,
          currentPetName: null,        // NEW
          nextPetName: nextPetName,    // NEW
        );
      }
    } catch (e) {
      debugPrint('WALK: error computing window: $e');
      return const WalkWindowResult.empty();
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Helpers

  /// Convert Postgres TIME string ("HH:MM" or "HH:MM:SS") to Duration since midnight.
  Duration? _pgTimeToDuration(String? s) {
    if (s == null) return null;
    final parts = s.split(':'); // e.g. "08:00:00"
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final sec = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;
    if (h < 0 || h > 23 || m < 0 || m > 59 || sec < 0 || sec > 59) return null;
    return Duration(hours: h, minutes: m, seconds: sec);
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Value object for the walking window

class WalkWindowResult {
  final bool isInWindow;
  final DateTime? currentStart;
  final DateTime? currentEnd;
  final DateTime? nextStart;
  final DateTime? nextEnd;
  final String? currentPetName;
  final String? nextPetName;

  const WalkWindowResult({
    required this.isInWindow,
    this.currentStart,
    this.currentEnd,
    this.nextStart,
    this.nextEnd,
    this.currentPetName,
    this.nextPetName,
  });

  const WalkWindowResult.empty()
      : isInWindow = false,
        currentStart = null,
        currentEnd = null,
        nextStart = null,
        nextEnd = null,
        currentPetName = null,
        nextPetName = null;
}
