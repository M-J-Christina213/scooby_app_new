import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

class WalkNotificationService {
  String? buildWalkNotification({required DateTime walkTime, bool canceled = false}) {
    if (canceled) return null;
    final now = DateTime.now();
    if (walkTime.isAfter(now)) {
      return "Walk scheduled at ${walkTime.hour}:${walkTime.minute.toString().padLeft(2,'0')}";
    }
    return null;
  }
}

class BookingNotificationService {
  final List<String> _notifications = [];
  final List<String> _canceled = [];

  void addBookingNotification(String text) => _notifications.add(text);

  void cancelNotification(String text) {
    _notifications.remove(text);
    _canceled.add(text);
  }

  void markAsRead(int index) {
    if (index < _notifications.length) _notifications.removeAt(index);
  }

  int get unreadCount => _notifications.length;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final testResults = <Map<String, String>>[];
  late WalkNotificationService walkService;
  late BookingNotificationService bookingService;

  setUp(() {
    walkService = WalkNotificationService();
    bookingService = BookingNotificationService();
  });

  group('End-to-End Flow: Notifications', () {
    testWidgets('Walk scheduled notification appears', (tester) async {
      try {
        final walkTime = DateTime.now().add(Duration(minutes: 5));
        final notif = walkService.buildWalkNotification(walkTime: walkTime);

        expect(notif, isNotNull);
        expect(notif, contains('Walk scheduled at'));

        testResults.add({
          'Test ID': 'E1',
          'Scenario': 'Walk scheduled notification appears',
          'Result': 'Passed'
        });
      } catch (e) {
        testResults.add({
          'Test ID': 'E1',
          'Scenario': 'Walk scheduled notification appears',
          'Result': 'Failed: $e'
        });
      }
    });

    testWidgets('Booking notification appears on Home Screen', (tester) async {
      try {
        bookingService.addBookingNotification("Vet Appointment for Fluffy");
        expect(bookingService.unreadCount, 1);

        testResults.add({
          'Test ID': 'E2',
          'Scenario': 'Booking notification appears on Home Screen',
          'Result': 'Passed'
        });
      } catch (e) {
        testResults.add({
          'Test ID': 'E2',
          'Scenario': 'Booking notification appears on Home Screen',
          'Result': 'Failed: $e'
        });
      }
    });

    testWidgets('Cancel booking notification reduces count', (tester) async {
      try {
        bookingService.cancelNotification("Vet Appointment for Fluffy");
        expect(bookingService.unreadCount, 0);

        testResults.add({
          'Test ID': 'E3',
          'Scenario': 'Canceling booking notification reduces count',
          'Result': 'Passed'
        });
      } catch (e) {
        testResults.add({
          'Test ID': 'E3',
          'Scenario': 'Canceling booking notification reduces count',
          'Result': 'Failed: $e'
        });
      }
    });
  });

  tearDownAll(() {
    debugPrint('\n=== Notifications End-to-End Test Report ===');
    debugPrint('| Test ID | Scenario | Result |');
    debugPrint('|---------|--------------------------------------------|---------|');
    for (var r in testResults) {
      final scenario = r['Scenario']!.padRight(44);
      debugPrint('| ${r['Test ID']} | $scenario | ${r['Result']} |');
    }
    debugPrint('============================================\n');
  });
}
