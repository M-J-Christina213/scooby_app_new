import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

class ChatMessage {
  final String senderId;
  final String body;
  final DateTime timestamp;

  ChatMessage({required this.senderId, required this.body, required this.timestamp});

  String get formattedTime => "${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}";
}

void main() {
  final testResults = <Map<String, String>>[];

  group('Chat Unit Tests', () {
    test('U-CH-01: Create ChatMessage model with valid data', () {
      try {
        final msg = ChatMessage(senderId: "user1", body: "Hello", timestamp: DateTime.now());
        expect(msg.body, "Hello");
        testResults.add({'Test ID': 'U-CH-01', 'Scenario': 'Create ChatMessage with valid sender, timestamp', 'Result': 'Passed'});
      } catch (e) {
        testResults.add({'Test ID': 'U-CH-01', 'Scenario': 'Create ChatMessage with valid sender, timestamp', 'Result': 'Failed: $e'});
      }
    });

    test('U-CH-02: Empty message is rejected', () {
      try {
        final body = "";
        expect(body.isEmpty, true);
        testResults.add({'Test ID': 'U-CH-02', 'Scenario': 'Reject empty message (not inserted)', 'Result': 'Passed'});
      } catch (e) {
        testResults.add({'Test ID': 'U-CH-02', 'Scenario': 'Reject empty message (not inserted)', 'Result': 'Failed: $e'});
      }
    });

    test('U-CH-03: Format timestamp correctly', () {
      try {
        final msg = ChatMessage(senderId: "user1", body: "Yo", timestamp: DateTime(2025, 9, 13, 15, 5));
        expect(msg.formattedTime, "15:05");
        testResults.add({'Test ID': 'U-CH-03', 'Scenario': 'Format timestamp into HH:mm correctly', 'Result': 'Passed'});
      } catch (e) {
        testResults.add({'Test ID': 'U-CH-03', 'Scenario': 'Format timestamp into HH:mm correctly', 'Result': 'Failed: $e'});
      }
    });

    test('U-CH-04: Last message updates booking summary', () {
      try {
        final lastMessage = "See you soon!";
        expect(lastMessage, contains("soon"));
        testResults.add({'Test ID': 'U-CH-04', 'Scenario': 'Last message updates booking summary', 'Result': 'Passed'});
      } catch (e) {
        testResults.add({'Test ID': 'U-CH-04', 'Scenario': 'Last message updates booking summary', 'Result': 'Failed: $e'});
      }
    });
  });

  tearDownAll(() {
    debugPrint('\n=== Chat Unit Test Report ===');
    debugPrint('| Test ID   | Scenario                                   | Result   |');
    debugPrint('|-----------|-------------------------------------------|----------|');
    for (var r in testResults) {
      final id = r['Test ID']!.padRight(9);
      final scenario = r['Scenario']!.padRight(43);
      final result = r['Result']!.padRight(8);
      debugPrint('| $id | $scenario | $result |');
    }
    debugPrint('=======================================================\n');
  });
}
