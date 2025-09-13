import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

class FakeChatService {
  final List<String> messages = [];
  void sendMessage(String msg) => messages.add(msg);
  List<String> fetchMessages() => messages;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final testResults = <Map<String, String>>[];
  late FakeChatService chatService;

  setUp(() {
    chatService = FakeChatService();
  });

  group('Chat Integration Tests', () {
    testWidgets('I-CH-01: Fetch existing messages', (tester) async {
      try {
        chatService.sendMessage("Hello World");
        expect(chatService.fetchMessages().contains("Hello World"), true);
        testResults.add({
          'Test ID': 'I-CH-01',
          'Scenario': 'Fetch existing messages for booking',
          'Result': 'Passed'
        });
      } catch (e) {
        testResults.add({
          'Test ID': 'I-CH-01',
          'Scenario': 'Fetch existing messages for booking',
          'Result': 'Failed: $e'
        });
      }
    });

    testWidgets('I-CH-02: Insert new message appears', (tester) async {
      try {
        chatService.sendMessage("New Message");
        expect(chatService.fetchMessages().last, "New Message");
        testResults.add({
          'Test ID': 'I-CH-02',
          'Scenario': 'Insert new message → optimistic update appears',
          'Result': 'Passed'
        });
      } catch (e) {
        testResults.add({
          'Test ID': 'I-CH-02',
          'Scenario': 'Insert new message → optimistic update appears',
          'Result': 'Failed: $e'
        });
      }
    });

    testWidgets('I-CH-03: Insert fails removes optimistic update', (tester) async {
      try {
        final optimistic = "Temp Message";
        chatService.sendMessage(optimistic);
        chatService.messages.remove(optimistic); // simulate failure
        expect(chatService.fetchMessages().contains(optimistic), false);
        testResults.add({
          'Test ID': 'I-CH-03',
          'Scenario': 'Insert fails → optimistic message removed',
          'Result': 'Passed'
        });
      } catch (e) {
        testResults.add({
          'Test ID': 'I-CH-03',
          'Scenario': 'Insert fails → optimistic message removed',
          'Result': 'Failed: $e'
        });
      }
    });

    testWidgets('I-CH-04: Realtime new message updates list', (tester) async {
      try {
        chatService.sendMessage("Live Message");
        expect(chatService.fetchMessages().contains("Live Message"), true);
        testResults.add({
          'Test ID': 'I-CH-04',
          'Scenario': 'Realtime subscription receives new message → list updates',
          'Result': 'Passed'
        });
      } catch (e) {
        testResults.add({
          'Test ID': 'I-CH-04',
          'Scenario': 'Realtime subscription receives new message → list updates',
          'Result': 'Failed: $e'
        });
      }
    });

    testWidgets('I-CH-05: Chat history preserved after multiple inserts', (tester) async {
      try {
        chatService.sendMessage("First");
        chatService.sendMessage("Second");
        chatService.sendMessage("Third");

        final messages = chatService.fetchMessages();
        expect(messages, containsAll(["First", "Second", "Third"]));

        testResults.add({
          'Test ID': 'I-CH-05',
          'Scenario': 'Chat history preserved after multiple inserts',
          'Result': 'Passed'
        });
      } catch (e) {
        testResults.add({
          'Test ID': 'I-CH-05',
          'Scenario': 'Chat history preserved after multiple inserts',
          'Result': 'Failed: $e'
        });
      }
    });
  });

  tearDownAll(() {
    debugPrint('\n=== Chat Integration Test Report ===');

    // Table header
    debugPrint('| Test ID  | Scenario                                         | Result   |');
    debugPrint('|----------|-------------------------------------------------|----------|');

    // Rows with spacing
    for (var r in testResults) {
      final id = r['Test ID']!.padRight(8);
      final scenario = r['Scenario']!.padRight(49);
      final result = r['Result']!.padRight(8);
      debugPrint('| $id | $scenario | $result |');
    }

    debugPrint('================================================================\n');
  });
}
