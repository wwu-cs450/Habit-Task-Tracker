import 'package:flutter_test/flutter_test.dart';
import 'package:habit_task_tracker/log.dart';

// Test to verify saving and loading Log objects from the localstore database
void main() {
  group('Log Database Test', () {
    test('Save and Load Log', () async {
      // Create a test log
      DateTime testTimestamp = DateTime(2025, 11, 5, 10, 30);
      Log testLog = Log(
        id: 'test_log_1',
        timestamp: testTimestamp,
        habitId: 'habit_123',
        notes: 'Drank 30 gallons of water',
      );

      // Save the log to the database
      int saveResult = await saveLog(testLog);
      expect(saveResult, equals(0));

      // Load the log from the database
      Log loadedLog = await loadLog(testLog.gId);

      // Verify the loaded log matches the saved log
      expect(loadedLog.gId, equals(testLog.gId));
      expect(loadedLog.gTimestamp, equals(testLog.gTimestamp));
      expect(loadedLog.gHabitId, equals(testLog.gHabitId));
      expect(loadedLog.gNotes, equals(testLog.gNotes));
    });

    test('Save and Load Log without notes', () async {
      // Create a test log without notes
      DateTime testTimestamp = DateTime(2025, 11, 5, 14, 45);
      Log testLog = Log(
        id: 'test_log_2',
        timestamp: testTimestamp,
        habitId: 'habit_456',
      );

      // Save the log to the database
      int saveResult = await saveLog(testLog);
      expect(saveResult, equals(0));

      // Load the log from the database
      Log loadedLog = await loadLog(testLog.gId);

      // Verify the loaded log matches the saved log
      expect(loadedLog.gId, equals(testLog.gId));
      expect(loadedLog.gTimestamp, equals(testLog.gTimestamp));
      expect(loadedLog.gHabitId, equals(testLog.gHabitId));
      expect(loadedLog.gNotes, isNull);
    });

    test('Load non-existent log throws exception', () async {
      // Attempt to load a log that doesn't exist
      expect(() async => await loadLog('nonexistent_log'), throwsException);
    });
  });
}
