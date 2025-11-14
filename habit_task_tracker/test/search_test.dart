import 'package:habit_task_tracker/search.dart';
import 'package:habit_task_tracker/habit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Search Test', () {
    test('Search Habits by Name', () async {
      // Create and save sample habits
      Habit habit1 = Habit(
        id: 'search_habit_1',
        name: 'Exercise Daily',
        frequency: Frequency.daily,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
        isRecurring: true,
      );
      Habit habit2 = Habit(
        id: 'search_habit_2',
        name: 'Read Books',
        frequency: Frequency.weekly,
        startDate: DateTime(2024, 2, 1),
        endDate: DateTime(2024, 11, 30),
        isRecurring: false,
      );

      await saveHabit(habit1);
      await saveHabit(habit2);

      // Search for habit by name
      List<Habit> results = searchHabits(name: 'Exercise Daily');

      // Verify the search results
      expect(results.length, greaterThan(0));
      expect(results.any((habit) => habit.gName == 'Exercise Daily'), isTrue);
    });
  });
}