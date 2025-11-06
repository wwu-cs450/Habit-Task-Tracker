import 'package:flutter_test/flutter_test.dart';
import 'package:habit_task_tracker/habit.dart';

void main() {
  group('Habit Model Test', () {
    test('Create Habit Instance', () {
      final habit = Habit(
        id: 'habit_1',
        name: 'Exercise',
        frequency: Frequency.daily,
        startDate: DateTime(2024, 1, 1),
      );

      expect(habit.id, 'habit_1');
      expect(habit.name, 'Exercise');
      expect(habit.frequency, 'Daily');
      expect(habit.startDate, DateTime(2024, 1, 1));
    });
  });
}
