import 'dart:math';

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
      List<Habit> results = await searchHabits(name: 'Exercise Daily');

      // Verify the search results
      expect(results.length, greaterThan(0));
      expect(results.any((habit) => habit.gName == 'Exercise Daily'), isTrue);
    });

    test('Search Habits between Dates', () async {
      // Create and save sample habits
      Habit habit3 = Habit(
        id: 'search_habit_3',
        name: 'Meditate',
        frequency: Frequency.daily,
        startDate: DateTime(2024, 3, 1),
        endDate: DateTime(2024, 9, 30),
        isRecurring: true,
      );
      Habit habit4 = Habit(
        id: 'search_habit_4',
        name: 'Yoga',
        frequency: Frequency.weekly,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 11, 31),
        isRecurring: false,
      );

      await saveHabit(habit3);
      await saveHabit(habit4);

      // Search for habits between specific dates
      DateTime date1 = DateTime(2024, 2, 1);
      DateTime date2 = DateTime(2024, 10, 1);
      List<Habit> results = await searchHabits(date1: date1, date2: date2);

      // Verify the search results
      expect(results.length, equals(1));
      expect(results.any((habit) => habit.gName == 'Meditate'), isTrue);
      expect(results.any((habit) => habit.gName == 'Yoga'), isFalse);
    });

    test('Search Habits by Description', () async {
      // Create and save sample habits
      Habit habit5 = Habit(
        id: 'search_habit_5',
        name: 'Journaling',
        description: 'Write daily journal entries',
        frequency: Frequency.daily,
        startDate: DateTime(2024, 4, 1),
        endDate: DateTime(2024, 10, 31),
        isRecurring: true,
      );
      Habit habit6 = Habit(
        id: 'search_habit_6',
        name: 'Cooking',
        description: 'Try new recipes weekly',
        frequency: Frequency.weekly,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
        isRecurring: false,
      );

      await saveHabit(habit5);
      await saveHabit(habit6);

      // Search for habit by description
      List<Habit> results = await searchHabits(description: 'journal');

      // Verify the search results
      expect(results.length, greaterThan(0));
      expect(results.any((habit) => habit.gName == 'Journaling'), isTrue);
    });
  });
}