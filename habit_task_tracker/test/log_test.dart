import 'package:flutter_test/flutter_test.dart';
import 'package:habit_task_tracker/log.dart';
import 'package:habit_task_tracker/habit.dart';

// Test to verify saving and loading Log objects from the localstore database
void main() {
  group('Log Database Test', () {
    test('Save and Load Log', () async {
      // Create a test log
      DateTime testTimestamp = DateTime(2025, 11, 5, 10, 30);
      Log testLog = Log(
        habitId: 'habit_123',
        timeStamps: [testTimestamp],
        notes: 'Drank 30 gallons of water',
      );

      // Save the log to the database
      await saveLog(testLog);

      // Load the log from the database
      Log loadedLog = await loadLog(testLog.gId);

      // Verify the loaded log matches the saved log
      expect(loadedLog.gId, equals(testLog.gId));
      expect(loadedLog.gTimeStamps, equals(testLog.gTimeStamps));
      expect(loadedLog.gNotes, equals(testLog.gNotes));
    });

    test('Save and Load Log without notes', () async {
      // Create a test log without notes
      DateTime testTimestamp = DateTime(2025, 11, 5, 14, 45);
      Log testLog = Log(habitId: 'habit_456', timeStamps: [testTimestamp]);

      // Save the log to the database
      await saveLog(testLog);

      // Load the log from the database
      Log loadedLog = await loadLog(testLog.gId);

      // Verify the loaded log matches the saved log
      expect(loadedLog.gId, equals(testLog.gId));
      expect(loadedLog.gTimeStamps, equals(testLog.gTimeStamps));
      expect(loadedLog.gNotes, isNull);
    });

    test('Load non-existent log throws exception', () async {
      // Attempt to load a log that doesn't exist
      expect(() async => await loadLog('nonexistent_log'), throwsException);
    });
  });

  group('Log Class Methods', () {
    test('getCompletionPercentage returns correct value', () {
      final now = DateTime.now();
      final startDate = now.subtract(
        const Duration(days: 2),
      ); // 3 days including today
      Log log = Log(
        habitId: 'habit_789',
        timeStamps: [startDate, startDate.add(const Duration(days: 1)), now],
      );
      // 3 completions in 3 days, should be 100%
      expect(
        log.getCompletionPercentage(Frequency.daily, startDate),
        equals(100),
      );
      // 3 completions in 1 week, should be 100%
      expect(
        log.getCompletionPercentage(Frequency.weekly, startDate),
        equals(100),
      );
    });

    test('updateTimeStamps adds timestamp and saves', () async {
      Log log = Log(habitId: 'habit_999');
      DateTime newTime = DateTime(2025, 11, 13, 12, 0);
      await log.updateTimeStamps(newTime);
      expect(log.gTimeStamps.contains(newTime), isTrue);
    });

    test('updateNotes updates notes and saves', () async {
      Log log = Log(habitId: 'habit_888', notes: 'Initial note');
      String updatedNote = 'Updated note';
      await log.updateNotes(updatedNote);
      expect(log.gNotes, equals(updatedNote));
    });
  });
}
