import 'package:flutter_test/flutter_test.dart';
import 'package:habit_task_tracker/habit.dart';

void main() {
  group('Habit Model Test', () {
    test('Create Habit Instance', () {
      final habit = Habit.recurring(
        id: 'habit_1',
        name: 'Exercise',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
      ).addRecurrence(Frequency.daily);

      expect(habit.gId, 'habit_1');
      expect(habit.gName, 'Exercise');
      expect(habit.gRecurrences.first.freq, Frequency.daily);
      expect(habit.gStartDate, DateTime(2024, 1, 1));
    });
    test('Save and Load Habit', () async {
      Habit? habit = Habit.recurring(
        id: 'habit_2',
        name: 'Read Books',
        startDate: DateTime(2024, 2, 2),
        endDate: DateTime(2024, 11, 30),
      ).addRecurrence(Frequency.daily);

      await saveHabit(habit);

      Habit habitLate = await loadHabit('habit_2');

      expect(habitLate.gId, 'habit_2');
      expect(habitLate.gName, 'Read Books');
      expect(habitLate.gRecurrences.first.freq, Frequency.daily);
      expect(habitLate.gStartDate, DateTime(2024, 2, 2));
      expect(habitLate.gEndDate, DateTime(2024, 11, 30));
      expect(habitLate.gIsRecurring, true);
    });

    test('Habit Frequency Null Test', () async {
      final habit = Habit.recurring(
        id: 'habit_3',
        name: 'Run Marathon',
        startDate: DateTime(2024, 3, 3),
        endDate: DateTime(2024, 10, 31),
      );
      expect(habit.gRecurrences.isEmpty, true);
    });

    test('Habit toJson and fromJson Test', () {
      final habit = Habit.recurring(
        id: 'habit_4',
        name: 'Meditate',
        description: 'Daily meditation for 10 minutes',
        startDate: DateTime(2024, 4, 4),
        endDate: DateTime(2024, 9, 30),
      ).addRecurrence(Frequency.daily);

      final json = habit.toJson();
      expect(json['id'], 'habit_4');
      expect(json['name'], 'Meditate');
      expect(json['description'], 'Daily meditation for 10 minutes');
      expect(json['startDate'], '2024-04-04T00:00:00.000');
      expect(json['endDate'], '2024-09-30T00:00:00.000');
      expect(json['isRecurring'], true);
      expect(json['recurrences'].first['freq'], 'Frequency.daily');

      final habitFromJson = Habit.fromJson(json);
      expect(habitFromJson.gId, 'habit_4');
      expect(habitFromJson.gName, 'Meditate');
      expect(habitFromJson.description, 'Daily meditation for 10 minutes');
      expect(habitFromJson.gStartDate, DateTime(2024, 4, 4));
      expect(habitFromJson.gEndDate, DateTime(2024, 9, 30));
      expect(habitFromJson.gIsRecurring, true);
      expect(habitFromJson.gRecurrences.first.freq, Frequency.daily);
    });

    test('Delete Habit Test', () async {
      final habit = Habit.oneTime(
        id: 'habit_8',
        name: 'Habit to Delete',
        startDate: DateTime(2024, 5, 5),
        endDate: DateTime(2024, 10, 5),
      );

      await saveHabit(habit);

      await deleteHabit('habit_8');
      dynamic loadedHabit;
      // expect error from loading deleted habit
      try {
        loadedHabit = await loadHabit('habit_8');
      } catch (e) {
        loadedHabit = null;
      }

      expect(loadedHabit, isNull);
    });
    test('Correct creation of Log', () {
      final habit = Habit.recurring(
        id: 'habit_8',
        name: 'Test Habit for Log',
        startDate: DateTime(2024, 5, 5),
        endDate: DateTime(2024, 12, 31),
      ).addRecurrence(Frequency.daily);

      expect(habit.log.gId, equals(habit.gId));
      expect(habit.log.timeStamps, isEmpty);
      expect(habit.log.notes, isNull);
    });

    test('Change Habit name, discription, and dates', () async {
      final habit = Habit.oneTime(
        id: 'habit_9',
        name: 'Initial Name',
        description: 'Initial Description',
        startDate: DateTime(2024, 6, 1),
        endDate: DateTime(2024, 12, 1),
      );

      await saveHabit(habit);

      await changeHabit(
        'habit_9',
        name: 'Modified Name',
        description: 'Modified Description',
        startDate: DateTime(2024, 7, 1),
        endDate: DateTime(2024, 11, 1),
      );

      final loadedHabit = await loadHabit('habit_9');
      expect(loadedHabit.gName, 'Modified Name');
      expect(loadedHabit.description, 'Modified Description');
      expect(loadedHabit.gStartDate, DateTime(2024, 7, 1));
      expect(loadedHabit.gEndDate, DateTime(2024, 11, 1));
    });

    test('Add intervals to habit', () async {
      final habit =
          Habit.recurring(
                id: 'habit_10',
                name: 'Interval Habit',
                startDate: DateTime(2024, 8, 1),
                endDate: DateTime(2024, 12, 31),
              )
              .addRecurrence(Frequency.weekly, DateTime(2024, 8, 1))
              .addRecurrence(Frequency.weekly, DateTime(2024, 8, 3))
              .addRecurrence(Frequency.weekly, DateTime(2024, 8, 5));

      await saveHabit(habit);

      final loadedHabit = await loadHabit('habit_10');
      expect(
        loadedHabit.gRecurrences.every(
          (element) => element.freq == Frequency.weekly,
        ),
        true,
      );
      expect(loadedHabit.gRecurrences.length, 3);
      expect(
        loadedHabit.gRecurrences.map((e) => e.startDate).toList(),
        containsAll([
          DateTime(2024, 8, 1),
          DateTime(2024, 8, 3),
          DateTime(2024, 8, 5),
        ]),
      );
    });
    test("Get habits from habit (daily)", () async {
      final habit =
          Habit.recurring(
                id: 'habit_12',
                name: 'Recurring Habit',
                startDate: DateTime(2024, 10, 1),
                endDate: DateTime(2024, 10, 10),
              )
              .addRecurrence(Frequency.daily, DateTime(2024, 10, 1, 8, 0, 0))
              .addRecurrence(Frequency.daily, DateTime(2024, 10, 1, 20, 0, 0));

      await saveHabit(habit);

      final habitDates = await getHabitDates(
        'habit_12',
        DateTime(2024, 10, 5, 23, 59, 59),
      );
      expect(habitDates.length, 10);
      expect(
        habitDates,
        containsAll([
          DateTime(2024, 10, 1, 8, 0, 0),
          DateTime(2024, 10, 1, 20, 0, 0),
          DateTime(2024, 10, 2, 8, 0, 0),
          DateTime(2024, 10, 2, 20, 0, 0),
          DateTime(2024, 10, 3, 8, 0, 0),
          DateTime(2024, 10, 3, 20, 0, 0),
          DateTime(2024, 10, 4, 8, 0, 0),
          DateTime(2024, 10, 4, 20, 0, 0),
          DateTime(2024, 10, 5, 8, 0, 0),
          DateTime(2024, 10, 5, 20, 0, 0),
        ]),
      );
    });

    test("Get habits from habit (weekly)", () async {
      final habit =
          Habit.recurring(
                id: 'habit_11',
                name: 'Weekly Habit',
                startDate: DateTime(2024, 9, 1),
                endDate: DateTime(2024, 9, 30),
              )
              .addRecurrence(Frequency.weekly, DateTime(2024, 9, 1))
              .addRecurrence(Frequency.weekly, DateTime(2024, 9, 3));

      await saveHabit(habit);

      final habitDates = await getHabitDates('habit_11', DateTime(2024, 9, 25));
      expect(habitDates.length, 8);
      expect(
        habitDates,
        containsAll([
          DateTime(2024, 9, 1),
          DateTime(2024, 9, 3),
          DateTime(2024, 9, 8),
          DateTime(2024, 9, 10),
          DateTime(2024, 9, 15),
          DateTime(2024, 9, 17),
          DateTime(2024, 9, 22),
          DateTime(2024, 9, 24),
        ]),
      );
    });
    test("Get habits from habit (non-recurring)", () async {
      final habit = Habit.oneTime(
        id: 'habit_13',
        name: 'One-time Habit',
        startDate: DateTime(2024, 11, 15),
        endDate: DateTime(2024, 11, 15),
      );

      await saveHabit(habit);

      final habitDates = await getHabitDates('habit_13', DateTime(2024, 12, 1));
      expect(habitDates.length, 1);
      expect(habitDates, containsAll([DateTime(2024, 11, 15)]));
    });

    test("Get habits from habit (monthly)", () async {
      final habit =
          Habit.recurring(
                id: 'habit_14',
                name: 'Monthly Habit',
                startDate: DateTime(2024, 1, 15),
                endDate: DateTime(2024, 6, 15),
              )
              .addRecurrence(Frequency.monthly, DateTime(2024, 1, 15))
              .addRecurrence(Frequency.monthly, DateTime(2024, 1, 30));

      await saveHabit(habit);

      final habitDates = await getHabitDates('habit_14', DateTime(2024, 6, 30));
      expect(habitDates.length, 11);
      expect(
        habitDates,
        containsAll([
          DateTime(2024, 1, 15),
          DateTime(2024, 1, 30),
          DateTime(2024, 2, 15),
          DateTime(2024, 2, 29),
          DateTime(2024, 3, 15),
          DateTime(2024, 3, 30),
          DateTime(2024, 4, 15),
          DateTime(2024, 4, 30),
          DateTime(2024, 5, 15),
          DateTime(2024, 5, 30),
          DateTime(2024, 6, 15),
        ]),
      );
    });

    test("Get habits from habit (yearly)", () async {
      final habit = Habit.recurring(
        id: 'habit_15',
        name: 'Yearly Habit',
        startDate: DateTime(2020, 2, 29),
        endDate: DateTime(2024, 2, 29),
      ).addRecurrence(Frequency.yearly);

      await saveHabit(habit);

      final habitDates = await getHabitDates(
        'habit_15',
        DateTime(2024, 12, 31),
      );
      expect(habitDates.length, 5);
      expect(
        habitDates,
        containsAll([
          DateTime(2020, 2, 29),
          DateTime(2021, 2, 28),
          DateTime(2022, 2, 28),
          DateTime(2023, 2, 28),
          DateTime(2024, 2, 29),
        ]),
      );
    });
  });
}
