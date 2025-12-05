import 'package:flutter_test/flutter_test.dart';
import 'package:habit_task_tracker/habit.dart';
import 'package:habit_task_tracker/uuid.dart';
import '_setup_mocks.dart';

void main() {
  setUpAll(setupMocks);
  setUp(clearTestHabitsFolder);

  group('Habit Model Test', () {
    test('Create Habit Instance', () {
      final id = Uuid.generate().toString();
      final habit = Habit.recurring(
        id: id,
        name: 'Exercise',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
      ).addRecurrence(Frequency.daily);

      expect(habit.gId, id.toString());
      expect(habit.gName, 'Exercise');
      expect(habit.gRecurrences.first.freq, Frequency.daily);
      expect(habit.gStartDate, DateTime(2024, 1, 1));
    });
    test('Save and Load Habit', () async {
      final id = Uuid.generate().toString();
      Habit? habit = Habit.recurring(
        id: id,
        name: 'Read Books',
        startDate: DateTime(2024, 2, 2),
        endDate: DateTime(2024, 11, 30),
      ).addRecurrence(Frequency.daily);

      await saveTestHabit(habit);

      Habit habitLate = await loadTestHabit(habit.gId);

      expect(habitLate.gId, habit.gId);
      expect(habitLate.gName, 'Read Books');
      expect(habitLate.gRecurrences.first.freq, Frequency.daily);
      expect(habitLate.gStartDate, DateTime(2024, 2, 2));
      expect(habitLate.gEndDate, DateTime(2024, 11, 30));
      expect(habitLate.gIsRecurring, true);
    });

    test('Habit Frequency Null Test', () async {
      final id = Uuid.generate().toString();
      final habit = Habit.recurring(
        id: id,
        name: 'Run Marathon',
        startDate: DateTime(2024, 3, 3),
        endDate: DateTime(2024, 10, 31),
      );
      expect(habit.gRecurrences.isEmpty, true);
    });

    test('Habit toJson and fromJson Test', () {
      final id = Uuid.generate().toString();
      final habit = Habit.recurring(
        id: id,
        name: 'Meditate',
        description: 'Daily meditation for 10 minutes',
        startDate: DateTime(2024, 4, 4),
        endDate: DateTime(2024, 9, 30),
      ).addRecurrence(Frequency.daily);

      final json = habit.toJson();
      expect(json['id'], id);
      expect(json['name'], 'Meditate');
      expect(json['description'], 'Daily meditation for 10 minutes');
      expect(json['startDate'], '2024-04-04T00:00:00.000');
      expect(json['endDate'], '2024-09-30T00:00:00.000');
      expect(json['isRecurring'], true);
      expect(json['recurrences'].first['freq'], 'Frequency.daily');

      final habitFromJson = Habit.fromJson(json);
      expect(habitFromJson.gId, id);
      expect(habitFromJson.gName, 'Meditate');
      expect(habitFromJson.description, 'Daily meditation for 10 minutes');
      expect(habitFromJson.gStartDate, DateTime(2024, 4, 4));
      expect(habitFromJson.gEndDate, DateTime(2024, 9, 30));
      expect(habitFromJson.gIsRecurring, true);
      expect(habitFromJson.gRecurrences.first.freq, Frequency.daily);
    });

    test('Conversion from old ID format to new ID format', () {
      // create a habit with an old ID format using JSON
      final json = {
        'id': '1234567890',
        'name': 'Meditate',
        'startDate': '2024-04-04T00:00:00.000',
        'endDate': '2024-09-30T00:00:00.000',
        'isRecurring': true,
        'recurrences': [
          {'freq': 'Frequency.daily'},
        ],
      };
      final habit = Habit.fromJson(json);
      expect(habit.gId, isNot(equals('1234567890')));
      expect(habit.gName, 'Meditate');
      expect(habit.gStartDate, DateTime(2024, 4, 4));
      expect(habit.gEndDate, DateTime(2024, 9, 30));
      expect(habit.gIsRecurring, true);
      expect(habit.gRecurrences.first.freq, Frequency.daily);
    });

    test('Conversion from old ID format to new ID format', () {
      // create a habit with an old ID format using JSON
      final json = {
        'id': '1234567890',
        'name': 'Meditate',
        'startDate': '2024-04-04T00:00:00.000',
        'endDate': '2024-09-30T00:00:00.000',
        'isRecurring': true,
        'recurrences': [
          {'freq': 'Frequency.daily'},
        ],
      };
      final habit = Habit.fromJson(json);
      expect(habit.gId, isNot(equals('1234567890')));
      expect(habit.gName, 'Meditate');
      expect(habit.gStartDate, DateTime(2024, 4, 4));
      expect(habit.gEndDate, DateTime(2024, 9, 30));
      expect(habit.gIsRecurring, true);
      expect(habit.gRecurrences.first.freq, Frequency.daily);
    });

    test('Conversion from old ID format to new ID format', () {
      // create a habit with an old ID format using JSON
      final json = {
        'id': '1234567890',
        'name': 'Meditate',
        'startDate': '2024-04-04T00:00:00.000',
        'endDate': '2024-09-30T00:00:00.000',
        'isRecurring': true,
        'recurrences': [
          {'freq': 'Frequency.daily'},
        ],
      };
      final habit = Habit.fromJson(json);
      expect(habit.gId, isNot(equals('1234567890')));
      expect(habit.gName, 'Meditate');
      expect(habit.gStartDate, DateTime(2024, 4, 4));
      expect(habit.gEndDate, DateTime(2024, 9, 30));
      expect(habit.gIsRecurring, true);
      expect(habit.gRecurrences.first.freq, Frequency.daily);
    });

    test('Delete Habit Test', () async {
      final habit = Habit.oneTime(
        name: 'Habit to Delete',
        startDate: DateTime(2024, 5, 5),
        endDate: DateTime(2024, 10, 5),
      );

      final habitId = habit.gId;
      await saveTestHabit(habit);

      await deleteTestHabit(habitId);
      dynamic loadedHabit;
      // expect error from loading deleted habit
      try {
        loadedHabit = await loadTestHabit(habitId);
      } catch (e) {
        loadedHabit = null;
      }

      expect(loadedHabit, isNull);
    });
    test('Correct creation of Log', () {
      final id = Uuid.generate().toString();
      final habit = Habit.recurring(
        id: id,
        name: 'Test Habit for Log',
        startDate: DateTime(2024, 5, 5),
        endDate: DateTime(2024, 12, 31),
      );
      // habit.addRecurrence(Frequency.daily);

      expect(habit.log.gId, equals(Uuid.fromString(id)));
      expect(habit.log.timeStamps, isEmpty);
      expect(habit.log.notes, isNull);
    });

    test('Change Habit name, description, and dates', () async {
      final habit = Habit.oneTime(
        name: 'Initial Name',
        description: 'Initial Description',
        startDate: DateTime(2024, 6, 1),
        endDate: DateTime(2024, 12, 1),
      );

      final habitId = habit.gId;
      await saveTestHabit(habit);

      await changeHabit(
        habitId,
        name: 'Modified Name',
        description: 'Modified Description',
        startDate: DateTime(2024, 7, 1),
        endDate: DateTime(2024, 11, 1),
        test: true,
      );

      final loadedHabit = await loadTestHabit(habitId);
      expect(loadedHabit.gName, 'Modified Name');
      expect(loadedHabit.description, 'Modified Description');
      expect(loadedHabit.gStartDate, DateTime(2024, 7, 1));
      expect(loadedHabit.gEndDate, DateTime(2024, 11, 1));
    });

    test('Add intervals to habit', () async {
      final habit =
          Habit.recurring(
                name: 'Interval Habit',
                startDate: DateTime(2024, 8, 1),
                endDate: DateTime(2024, 12, 31),
              )
              .addRecurrence(Frequency.weekly, DateTime(2024, 8, 1))
              .addRecurrence(Frequency.weekly, DateTime(2024, 8, 3))
              .addRecurrence(Frequency.weekly, DateTime(2024, 8, 5));

      final habitId = habit.gId;
      await saveTestHabit(habit);

      final loadedHabit = await loadTestHabit(habitId);
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
                name: 'Recurring Habit',
                startDate: DateTime(2024, 10, 1),
                endDate: DateTime(2024, 10, 10),
              )
              .addRecurrence(Frequency.daily, DateTime(2024, 10, 1, 8, 0, 0))
              .addRecurrence(Frequency.daily, DateTime(2024, 10, 1, 20, 0, 0));

      final habitId = habit.gId;
      await saveTestHabit(habit);

      final habitDates = await getHabitDates(
        habitId,
        DateTime(2024, 10, 5, 23, 59, 59),
        test: true,
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
                name: 'Weekly Habit',
                startDate: DateTime(2024, 9, 1),
                endDate: DateTime(2024, 9, 30),
              )
              .addRecurrence(Frequency.weekly, DateTime(2024, 9, 1))
              .addRecurrence(Frequency.weekly, DateTime(2024, 9, 3));

      final habitId = habit.gId;
      await saveTestHabit(habit);

      final habitDates = await getHabitDates(
        habitId,
        DateTime(2024, 9, 25),
        test: true,
      );
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
        name: 'One-time Habit',
        startDate: DateTime(2024, 11, 15),
        endDate: DateTime(2024, 11, 15),
      );

      final habitId = habit.gId;
      await saveTestHabit(habit);

      final habitDates = await getHabitDates(
        habitId,
        DateTime(2024, 12, 1),
        test: true,
      );
      expect(habitDates.length, 1);
      expect(habitDates, containsAll([DateTime(2024, 11, 15)]));
    });

    test("Get habits from habit (monthly)", () async {
      final habit =
          Habit.recurring(
                name: 'Monthly Habit',
                startDate: DateTime(2024, 1, 15),
                endDate: DateTime(2024, 6, 15),
              )
              .addRecurrence(Frequency.monthly, DateTime(2024, 1, 15))
              .addRecurrence(Frequency.monthly, DateTime(2024, 1, 30));

      final habitId = habit.gId;
      await saveTestHabit(habit);

      final habitDates = await getHabitDates(
        habitId,
        DateTime(2024, 6, 30),
        test: true,
      );
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
        name: 'Yearly Habit',
        startDate: DateTime(2020, 2, 29),
        endDate: DateTime(2024, 2, 29),
      ).addRecurrence(Frequency.yearly);

      final habitId = habit.gId;
      await saveTestHabit(habit);

      final habitDates = await getHabitDates(
        habitId,
        DateTime(2024, 12, 31),
        test: true,
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
