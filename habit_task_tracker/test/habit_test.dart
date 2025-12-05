import 'package:flutter_test/flutter_test.dart';
import 'package:habit_task_tracker/habit.dart';
import 'package:habit_task_tracker/uuid.dart';
import '_setup_mocks.dart';

void main() {
  setUpAll(setupMocks);

  group('Habit Model Test', () {
    test('Create Habit Instance', () {
      final id = Uuid.generate().toString();
      final habit = Habit(
        id: id,
        name: 'Exercise',
        frequency: Frequency.daily,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
        isRecurring: false,
      );

      expect(habit.gId, id.toString());
      expect(habit.gName, 'Exercise');
      expect(habit.gFrequency, Frequency.daily);
      expect(habit.gStartDate, DateTime(2024, 1, 1));
    });
    test('Save and Load Habit', () async {
      final id = Uuid.generate().toString();
      Habit? habit = Habit(
        id: id,
        name: 'Read Books',
        frequency: Frequency.daily,
        startDate: DateTime(2024, 2, 2),
        endDate: DateTime(2024, 11, 30),
        isRecurring: false,
      );

      await saveHabit(habit);

      Habit habitLate = await loadHabit(habit.gId);

      expect(habitLate.gId, habit.gId);
      expect(habitLate.gName, 'Read Books');
      expect(habitLate.gFrequency, Frequency.daily);
      expect(habitLate.gStartDate, DateTime(2024, 2, 2));
      expect(habitLate.gEndDate, DateTime(2024, 11, 30));
      expect(habitLate.gIsRecurring, false);
    });

    test('Habit Frequency Null Test', () async {
      final id = Uuid.generate().toString();
      final habit = Habit(
        id: id,
        name: 'Run Marathon',
        startDate: DateTime(2024, 3, 3),
        endDate: DateTime(2024, 10, 31),
        isRecurring: true,
      );
      expect(habit.gFrequency, Frequency.none);
    });

    test('Habit toJson and fromJson Test', () {
      final id = Uuid.generate().toString();
      final habit = Habit(
        id: id,
        name: 'Meditate',
        description: 'Daily meditation for 10 minutes',
        startDate: DateTime(2024, 4, 4),
        endDate: DateTime(2024, 9, 30),
        isRecurring: true,
        frequency: Frequency.daily,
      );

      final json = habit.toJson();
      expect(json['id'], id);
      expect(json['name'], 'Meditate');
      expect(json['description'], 'Daily meditation for 10 minutes');
      expect(json['startDate'], '2024-04-04T00:00:00.000');
      expect(json['endDate'], '2024-09-30T00:00:00.000');
      expect(json['isRecurring'], true);
      expect(json['frequency'], 'Frequency.daily');

      final habitFromJson = Habit.fromJson(json);
      expect(habitFromJson.gId, id);
      expect(habitFromJson.gName, 'Meditate');
      expect(habitFromJson.description, 'Daily meditation for 10 minutes');
      expect(habitFromJson.gStartDate, DateTime(2024, 4, 4));
      expect(habitFromJson.gEndDate, DateTime(2024, 9, 30));
      expect(habitFromJson.gIsRecurring, true);
      expect(habitFromJson.gFrequency, Frequency.daily);
    });

    test('Conversion from old ID format to new ID format', () {
      // create a habit with an old ID format using JSON
      final json = {
        'id': '1234567890',
        'name': 'Meditate',
        'startDate': '2024-04-04T00:00:00.000',
        'endDate': '2024-09-30T00:00:00.000',
        'isRecurring': true,
        'frequency': 'Frequency.daily',
      };
      final habit = Habit.fromJson(json);
      expect(habit.gId, isNot(equals('1234567890')));
      expect(habit.gName, 'Meditate');
      expect(habit.gStartDate, DateTime(2024, 4, 4));
      expect(habit.gEndDate, DateTime(2024, 9, 30));
      expect(habit.gIsRecurring, true);
      expect(habit.gFrequency, Frequency.daily);
    });

    test('Delete Habit Test', () async {
      final id = Uuid.generate().toString();
      final habit = Habit(
        id: id,
        name: 'Habit to Delete',
        startDate: DateTime(2024, 5, 5),
        endDate: DateTime(2024, 10, 5),
        isRecurring: false,
      );

      await saveHabit(habit);

      await deleteHabit(id);
      dynamic loadedHabit;
      // expect error from loading deleted habit
      try {
        loadedHabit = await loadHabit(id);
      } catch (e) {
        loadedHabit = null;
      }

      expect(loadedHabit, isNull);
    });
    test('Correct creation of Log', () {
      final id = Uuid.generate().toString();
      final habit = Habit(
        id: id,
        name: 'Test Habit for Log',
        startDate: DateTime(2024, 5, 5),
        endDate: DateTime(2024, 12, 31),
        isRecurring: true,
        frequency: Frequency.daily,
      );

      expect(habit.log.gId, equals(Uuid.fromString(id)));
      expect(habit.log.timeStamps, isEmpty);
      expect(habit.log.notes, isNull);
    });
  });
}
