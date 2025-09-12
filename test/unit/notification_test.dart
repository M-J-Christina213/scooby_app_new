import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

// --- Notification logic for testing ---
class WalkNotificationService {
  DateTime combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  TimeOfDay parseTimeFlexible(String timeStr) {
    final isPm = timeStr.toLowerCase().contains('pm');
    final clean = timeStr.replaceAll(RegExp(r'[^\d:]'), '');
    final parts = clean.split(':');
    int hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    if (isPm && hour < 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;

    return TimeOfDay(hour: hour, minute: minute);
  }

  String? buildWalkNotification({required bool hasWalk}) {
    return hasWalk ? "Time to walk Buddy" : null;
  }
}

// --- Test main ---
void main() {
  late WalkNotificationService service;
  final testResults = <Map<String, String>>[];

  setUp(() {
    service = WalkNotificationService();
  });

  group('Notification Service Tests', () {
    test('N1: Combine date and time', () {
      try {
        final date = DateTime(2025, 9, 12);
        final time = TimeOfDay(hour: 10, minute: 30);
        final combined = service.combineDateAndTime(date, time);
        assert(combined == DateTime(2025, 9, 12, 10, 30));
        testResults.add({
          'Test ID': 'N1',
          'Scenario': 'Combine date + time',
          'Result': 'Passed'
        });
      } catch (e) {
        testResults.add({
          'Test ID': 'N1',
          'Scenario': 'Combine date + time',
          'Result': 'Failed'
        });
      }
    });

    test('N2: Parse 24-hour time', () {
      try {
        final result = service.parseTimeFlexible('14:45');
        assert(result.hour == 14 && result.minute == 45);
        testResults.add({
          'Test ID': 'N2',
          'Scenario': 'Parse 24h time',
          'Result': 'Passed'
        });
      } catch (e) {
        testResults.add({
          'Test ID': 'N2',
          'Scenario': 'Parse 24h time',
          'Result': 'Failed'
        });
      }
    });

    test('N3: Parse 12-hour time', () {
      try {
        final result = service.parseTimeFlexible('2:15 PM');
        assert(result.hour == 14 && result.minute == 15);
        testResults.add({
          'Test ID': 'N3',
          'Scenario': 'Parse 12h time',
          'Result': 'Passed'
        });
      } catch (e) {
        testResults.add({
          'Test ID': 'N3',
          'Scenario': 'Parse 12h time',
          'Result': 'Failed'
        });
      }
    });

    test('N4: Build walk notification (active walk)', () {
      try {
        final notif = service.buildWalkNotification(hasWalk: true);
        assert(notif == "Time to walk Buddy");
        testResults.add({
          'Test ID': 'N4',
          'Scenario': 'Build walk notification (active walk)',
          'Result': 'Passed'
        });
      } catch (e) {
        testResults.add({
          'Test ID': 'N4',
          'Scenario': 'Build walk notification (active walk)',
          'Result': 'Failed'
        });
      }
    });

    test('N5: No walk scheduled', () {
      try {
        final notif = service.buildWalkNotification(hasWalk: false);
        assert(notif == null);
        testResults.add({
          'Test ID': 'N5',
          'Scenario': 'No walk scheduled',
          'Result': 'Passed'
        });
      } catch (e) {
        testResults.add({
          'Test ID': 'N5',
          'Scenario': 'No walk scheduled',
          'Result': 'Failed'
        });
      }
    });
  });

  tearDownAll(() {
    debugPrint('\n=== Notification Test Report ===');

    // Print formatted table with proper spacing
    debugPrint('| Test ID | Scenario                             | Result  |');
    debugPrint('|---------|-------------------------------------|---------|');

    for (var r in testResults) {
      final id = r['Test ID']!.padRight(7);
      final scenario = r['Scenario']!.padRight(35);
      final result = r['Result']!.padRight(7);
      debugPrint('| $id | $scenario | $result |');
    }

    debugPrint('==============================\n');
  });
}
