import 'package:habit_task_tracker/search.dart';
import 'package:habit_task_tracker/habit.dart';
import 'package:habit_task_tracker/frequency.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_task_tracker/uuid.dart';
import '_setup_mocks.dart';

void main() {
  setUpAll(setupMocks);
  setUp(clearTestHabitsFolder);

  group('Search Test', () {
    test('Search Habits by Name', () async {
      // Create and save sample habits
      final id1 = Uuid.generate().toString();
      final id2 = Uuid.generate().toString();
      Habit habit1 = Habit.recurring(
        id: id1,
        name: 'Exercise Daily',
        description: 'test task',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
      ).addRecurrence(Frequency.daily);
      Habit habit2 = Habit.oneTime(
        id: id2,
        name: 'Read Books',
        description: 'test task',
        startDate: DateTime(2024, 2, 1),
        endDate: DateTime(2024, 11, 30),
      );

      await saveTestHabit(habit1);
      await saveTestHabit(habit2);

      // Search for habit by name
      List<Habit> results = await searchHabits(
        name: 'Exercise Daily',
        test: true,
      );
      // Verify the search results
      expect(results.length, greaterThan(0));
      expect(results.any((habit) => habit.gName == 'Exercise Daily'), isTrue);
    });

    test('Search Habits between Dates', () async {
      // Create and save sample habits
      final id3 = Uuid.generate().toString();
      final id4 = Uuid.generate().toString();
      Habit habit3 = Habit.recurring(
        id: id3,
        name: 'Meditate',
        description: 'test task',
        startDate: DateTime(2024, 3, 1),
        endDate: DateTime(2024, 9, 30),
      ).addRecurrence(Frequency.daily);
      Habit habit4 = Habit.oneTime(
        id: id4,
        name: 'Yoga',
        description: 'test task',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 11, 31),
      );

      await saveTestHabit(habit3);
      await saveTestHabit(habit4);

      // Search for habits between specific dates
      DateTime date1 = DateTime(2024, 2, 1);
      DateTime date2 = DateTime(2024, 10, 1);
      List<Habit> results = await searchHabits(
        date1: date1,
        date2: date2,
        test: true,
      );

      // Verify the search results
      expect(results.length, equals(1));
      expect(results.any((habit) => habit.gName == 'Meditate'), isTrue);
      expect(results.any((habit) => habit.gName == 'Yoga'), isFalse);
    });

    test('Search Habits by Description', () async {
      // Create and save sample habits
      final id5 = Uuid.generate().toString();
      final id6 = Uuid.generate().toString();
      Habit habit5 = Habit.recurring(
        id: id5,
        name: 'Journaling',
        description: 'Write daily journal entries (test task)',
        startDate: DateTime(2024, 4, 1),
        endDate: DateTime(2024, 10, 31),
      ).addRecurrence(Frequency.daily);
      Habit habit6 = Habit.oneTime(
        id: id6,
        name: 'Cooking',
        description: 'Try new recipes weekly (test task)',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
      );

      await saveTestHabit(habit5);
      await saveTestHabit(habit6);

      // Search for habit by description
      List<Habit> results = await searchHabits(
        description: 'journal',
        test: true,
      );
      // Verify the search results
      expect(results.length, greaterThan(0));
      expect(results.any((habit) => habit.gName == 'Journaling'), isTrue);
    });
  });
}
