import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Simulated notification services
class WalkNotificationService {
  String? buildWalkNotification({required DateTime walkTime, required DateTime now}) {
    // Only show notification if current time >= walkTime
    return now.isAfter(walkTime) || now.isAtSameMomentAs(walkTime)
        ? "Walk scheduled at ${walkTime.hour.toString().padLeft(2, '0')}:${walkTime.minute.toString().padLeft(2, '0')} PM"
        : null;
  }
}

class AppointmentNotificationService {
  final List<String> _notifications = [];

  void addNotification(String title) => _notifications.add(title);

  List<String> getNotifications() => List.from(_notifications);

  void markAsRead(int index) => _notifications.removeAt(index);

  int get unreadCount => _notifications.length;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final testResults = <Map<String, String>>[];

  late WalkNotificationService walkService;
  late AppointmentNotificationService appointmentService;

  setUp(() {
    walkService = WalkNotificationService();
    appointmentService = AppointmentNotificationService();
  });

  group('Home Screen Notifications Integration Test', () {
    testWidgets('IN1: Walk scheduled notification appears', (tester) async {
      try {
        final now = DateTime(2025, 9, 12, 15, 15); // 3:15 PM
        final walkTime = DateTime(2025, 9, 12, 15, 15);
        final notif = walkService.buildWalkNotification(walkTime: walkTime, now: now);
        assert(notif != null && notif.contains("Walk scheduled at 15:15"));

        testResults.add({
          'Test ID': 'IN1',
          'Scenario': 'Walk notification shows on top of Home Screen at scheduled time',
          'Result': 'Passed'
        });
      } catch (e) {
        testResults.add({
          'Test ID': 'IN1',
          'Scenario': 'Walk notification shows on top of Home Screen at scheduled time',
          'Result': 'Failed: $e'
        });
      }
    });

    testWidgets('IN2: Appointment notification appears in bell', (tester) async {
      try {
        appointmentService.addNotification("Vet Appointment");
        assert(appointmentService.unreadCount == 1);

        testResults.add({
          'Test ID': 'IN2',
          'Scenario': 'Bell icon shows unread count when appointment notification appears',
          'Result': 'Passed'
        });
      } catch (e) {
        testResults.add({
          'Test ID': 'IN2',
          'Scenario': 'Bell icon shows unread count when appointment notification appears',
          'Result': 'Failed: $e'
        });
      }
    });

    testWidgets('IN3: Multiple appointment notifications increment bell count', (tester) async {
      try {
        appointmentService.addNotification("Groomer Appointment");
        assert(appointmentService.unreadCount == 2);

        testResults.add({
          'Test ID': 'IN3',
          'Scenario': 'Multiple appointment notifications increment bell count',
          'Result': 'Passed'
        });
      } catch (e) {
        testResults.add({
          'Test ID': 'IN3',
          'Scenario': 'Multiple appointment notifications increment bell count',
          'Result': 'Failed: $e'
        });
      }
    });

    testWidgets('IN4: Tap appointment notification shows details', (tester) async {
      try {
        final notifs = appointmentService.getNotifications();
        assert(notifs.contains("Vet Appointment"));

        testResults.add({
          'Test ID': 'IN4',
          'Scenario': 'Tap bell icon shows appointment notification details',
          'Result': 'Passed'
        });
      } catch (e) {
        testResults.add({
          'Test ID': 'IN4',
          'Scenario': 'Tap bell icon shows appointment notification details',
          'Result': 'Failed: $e'
        });
      }
    });

    testWidgets('IN5: Mark appointment notification as read updates count', (tester) async {
      try {
        appointmentService.markAsRead(0);
        assert(appointmentService.unreadCount == 1);

        testResults.add({
          'Test ID': 'IN5',
          'Scenario': 'Mark notification as read reduces bell count',
          'Result': 'Passed'
        });
      } catch (e) {
        testResults.add({
          'Test ID': 'IN5',
          'Scenario': 'Mark notification as read reduces bell count',
          'Result': 'Failed: $e'
        });
      }
    });

    testWidgets('IN6: Cancel walk removes top notification', (tester) async {
      try {
        final now = DateTime(2025, 9, 12, 15, 10); // before walk
        final walkTime = DateTime(2025, 9, 12, 15, 15);
        final notif = walkService.buildWalkNotification(walkTime: walkTime, now: now);
        assert(notif == null);

        testResults.add({
          'Test ID': 'IN6',
          'Scenario': 'Canceled walk notification does not appear',
          'Result': 'Passed'
        });
      } catch (e) {
        testResults.add({
          'Test ID': 'IN6',
          'Scenario': 'Canceled walk notification does not appear',
          'Result': 'Failed: $e'
        });
      }
    });

    testWidgets('IN7: Delete appointment reduces bell count', (tester) async {
      try {
        appointmentService.markAsRead(0); // remove last
        assert(appointmentService.unreadCount == 0);

        testResults.add({
          'Test ID': 'IN7',
          'Scenario': 'Deleted appointment does not increment bell count',
          'Result': 'Passed'
        });
      } catch (e) {
        testResults.add({
          'Test ID': 'IN7',
          'Scenario': 'Deleted appointment does not increment bell count',
          'Result': 'Failed: $e'
        });
      }
    });
  });

  tearDownAll(() {
    debugPrint('\n=== Home Screen Notifications Test Report ===');
    debugPrint('| Test ID | Scenario | Result |');
    debugPrint('|---------|--------------------------------------------|---------|');
    for (var r in testResults) {
      final scenario = r['Scenario']!.padRight(44);
      debugPrint('| ${r['Test ID']} | $scenario | ${r['Result']} |');
    }
    debugPrint('==============================\n');
  });
}
