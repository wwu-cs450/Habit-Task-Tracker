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

    test(
      'Search Habits by Name with Digit Matching - Exact digit match required',
      () async {
        // Create habits with similar names but different digits
        final id7 = Uuid.generate().toString();
        final id8 = Uuid.generate().toString();
        final id9 = Uuid.generate().toString();

        Habit habit7 = Habit.oneTime(
          id: id7,
          name: 'Habit 1',
          description: 'First habit',
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 12, 31),
        );
        Habit habit8 = Habit.oneTime(
          id: id8,
          name: 'Habit 10',
          description: 'Tenth habit',
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 12, 31),
        );
        Habit habit9 = Habit.oneTime(
          id: id9,
          name: 'Habit 11',
          description: 'Eleventh habit',
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 12, 31),
        );

        await saveTestHabit(habit7);
        await saveTestHabit(habit8);
        await saveTestHabit(habit9);

        // Search for "Habit 1" - should match only "Habit 1", not "Habit 10" or "Habit 11"
        List<Habit> results = await searchHabits(name: 'Habit 1', test: true);

        expect(results.length, equals(1));
        expect(results[0].gName, equals('Habit 1'));
      },
    );

    test('Search Habits by Name with multiple digits', () async {
      // Create habits with multi-digit numbers
      final id10 = Uuid.generate().toString();
      final id11 = Uuid.generate().toString();
      final id12 = Uuid.generate().toString();

      Habit habit10 = Habit.oneTime(
        id: id10,
        name: 'Phase 1 Task 5',
        description: 'Phase one task five',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
      );
      Habit habit11 = Habit.oneTime(
        id: id11,
        name: 'Phase 1 Task 50',
        description: 'Phase one task fifty',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
      );
      Habit habit12 = Habit.oneTime(
        id: id12,
        name: 'Phase 2 Task 5',
        description: 'Phase two task five',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
      );

      await saveTestHabit(habit10);
      await saveTestHabit(habit11);
      await saveTestHabit(habit12);

      // Search for "Phase 1 Task 5" - should match only the exact one
      List<Habit> results = await searchHabits(
        name: 'Phase 1 Task 5',
        test: true,
      );

      expect(results.length, equals(1));
      expect(results[0].gName, equals('Phase 1 Task 5'));
    });

    test('Search Habits by Description with Digit Matching', () async {
      // Create habits with similar descriptions but different digits
      final id13 = Uuid.generate().toString();
      final id14 = Uuid.generate().toString();
      final id15 = Uuid.generate().toString();

      Habit habit13 = Habit.oneTime(
        id: id13,
        name: 'Reading',
        description: 'Read chapter 1',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
      );
      Habit habit14 = Habit.oneTime(
        id: id14,
        name: 'Reading Book',
        description: 'Read chapter 10',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
      );
      Habit habit15 = Habit.oneTime(
        id: id15,
        name: 'Reading More',
        description: 'Read chapters 1 and 2',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
      );

      await saveTestHabit(habit13);
      await saveTestHabit(habit14);
      await saveTestHabit(habit15);

      // Search for "chapter 1" in description - should match habit13 and habit15
      List<Habit> results = await searchHabits(
        description: 'chapter 1',
        test: true,
      );

      expect(results.length, equals(2));
      expect(results.any((h) => h.gName == 'Reading'), isTrue);
      expect(results.any((h) => h.gName == 'Reading More'), isTrue);
      expect(results.any((h) => h.gName == 'Reading Book'), isFalse);
    });

    test(
      'Search Habits with query containing digit not in habit name returns empty',
      () async {
        // Create habit without the searched digit
        final id16 = Uuid.generate().toString();

        Habit habit16 = Habit.oneTime(
          id: id16,
          name: 'Morning Exercise',
          description: 'Morning routine',
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 12, 31),
        );

        await saveTestHabit(habit16);

        // Search for "Exercise 5" - should not match "Morning Exercise" (no digit 5)
        List<Habit> results = await searchHabits(
          name: 'Exercise 5',
          test: true,
        );

        expect(results.length, equals(0));
      },
    );

    test('Search Habits without digits ignores digit matching logic', () async {
      // Create habit with numbers in name
      final id17 = Uuid.generate().toString();
      final id18 = Uuid.generate().toString();

      Habit habit17 = Habit.oneTime(
        id: id17,
        name: 'Task 123',
        description: 'A task with numbers',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
      );
      Habit habit18 = Habit.oneTime(
        id: id18,
        name: 'Task 456',
        description: 'Another task',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
      );

      await saveTestHabit(habit17);
      await saveTestHabit(habit18);

      // Search for "Task" without digits - should match both (digit matching is skipped if no digits in query)
      List<Habit> results = await searchHabits(name: 'Task', test: true);

      expect(results.length, equals(2));
      expect(results.any((h) => h.gName == 'Task 123'), isTrue);
      expect(results.any((h) => h.gName == 'Task 456'), isTrue);
    });

    test('Substring matching prioritized over fuzzy matching', () async {
      // Create habits with names that could match via fuzzy but have clear substring matches
      final id19 = Uuid.generate().toString();
      final id20 = Uuid.generate().toString();
      final id21 = Uuid.generate().toString();

      Habit habit19 = Habit.oneTime(
        id: id19,
        name: 'Running Marathon',
        description: 'Long distance running',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
      );
      Habit habit20 = Habit.oneTime(
        id: id20,
        name: 'Sprint Race',
        description: 'Short distance running',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
      );
      Habit habit21 = Habit.oneTime(
        id: id21,
        name: 'Morning Run',
        description: 'Daily running routine',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
      );

      await saveTestHabit(habit19);
      await saveTestHabit(habit20);
      await saveTestHabit(habit21);

      // Search for "Marathon" - should return only "Running Marathon" via substring match
      // Even though "Sprint Race" and "Morning Run" might fuzzy match, substring takes priority
      List<Habit> results = await searchHabits(name: 'Marathon', test: true);

      expect(results.length, equals(1));
      expect(results[0].gName, equals('Running Marathon'));
    });

    test('Substring matching with partial words and special characters', () async {
      // Create habits with special characters and similar partial words
      final id22 = Uuid.generate().toString();
      final id23 = Uuid.generate().toString();
      final id24 = Uuid.generate().toString();

      Habit habit22 = Habit.oneTime(
        id: id22,
        name: 'C++ Programming',
        description: 'Learn C++ basics',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
      );
      Habit habit23 = Habit.oneTime(
        id: id23,
        name: 'Java Programming',
        description: 'Learn Java language',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
      );
      Habit habit24 = Habit.oneTime(
        id: id24,
        name: 'Python-Web Development',
        description: 'Web dev with Python',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
      );

      await saveTestHabit(habit22);
      await saveTestHabit(habit23);
      await saveTestHabit(habit24);

      // Search for "C++" - should match only "C++ Programming" via exact substring match
      List<Habit> results = await searchHabits(name: 'C++', test: true);

      expect(results.length, equals(1));
      expect(results[0].gName, equals('C++ Programming'));

      // Search for "Python" - should match only "Python-Web Development" via exact substring match
      List<Habit> results2 = await searchHabits(name: 'Python', test: true);

      expect(results2.length, equals(1));
      expect(results2[0].gName, equals('Python-Web Development'));
    });
  });
}
