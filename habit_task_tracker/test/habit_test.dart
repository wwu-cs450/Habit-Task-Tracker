import 'package:flutter_test/flutter_test.dart';
import 'package:habit_task_tracker/habit.dart';
import 'package:flutter/foundation.dart';

void main() {
  group('Habit Model Test', () {
    test('Create Habit Instance', () {
      final habit = Habit(
        id: 'habit_1',
        name: 'Exercise',
        frequency: Frequency.daily,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
        isRecurring: false,
      );

      expect(habit.gId, 'habit_1');
      expect(habit.gName, 'Exercise');
      expect(habit.gFrequency, Frequency.daily);
      expect(habit.gStartDate, DateTime(2024, 1, 1));
    });
    test('Save and Load Habit', () async {
      Habit? habit = Habit(
        id: 'habit_2',
        name: 'Read Books',
        frequency: Frequency.daily,
        startDate: DateTime(2024, 2, 2),
        endDate: DateTime(2024, 11, 30),
        isRecurring: false,
      );

      saveHabit(habit);

      // habit = null;

      Habit habitLate = await loadHabit('habit_2');

      //expect(habit, null);
      expect(habitLate.gId, 'habit_2');
      expect(habitLate.gName, 'Read Books');
      expect(habitLate.gFrequency, Frequency.daily);
      expect(habitLate.gStartDate, DateTime(2024, 2, 2));
      expect(habitLate.gEndDate, DateTime(2024, 11, 30));
      expect(habitLate.gIsRecurring, false);
    });

    test('Habit Frequency Null Test', () async {
      final habit = Habit(
        id: 'habit_3',
        name: 'Run Marathon',
        startDate: DateTime(2024, 3, 3),
        endDate: DateTime(2024, 10, 31),
        isRecurring: true,
      );
      expect(habit.gFrequency, Frequency.none);
    });
  });
}
