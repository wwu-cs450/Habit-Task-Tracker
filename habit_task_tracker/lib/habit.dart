import 'package:habit_task_tracker/backend.dart';
import 'package:habit_task_tracker/log.dart';
import 'package:habit_task_tracker/recurrence.dart';
import 'package:jiffy/jiffy.dart';

enum Frequency { daily, weekly, monthly, yearly, none }

Map<String, Frequency> frequencyMap = {
  'Frequency.daily': Frequency.daily,
  'Frequency.weekly': Frequency.weekly,
  'Frequency.monthly': Frequency.monthly,
  'Frequency.yearly': Frequency.yearly,
  'Frequency.none': Frequency.none,
};

Log createLog(String id, String? description) {
  return Log(habitId: id, notes: description);
}

class Habit {
  final String _id;
  dynamic _completed;
  String name;
  String? description;
  DateTime startDate;
  DateTime endDate;
  bool isRecurring;
  List<Recurrence> recurrences;
  Log log;

  Habit({
    required String id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.isRecurring,
    required this.recurrences,
    this.description,
  }) : _id = id,
       log = createLog(id, description);

  factory Habit.oneTime({
    required String id,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String? description,
  }) {
    return Habit(
      id: id,
      name: name,
      startDate: startDate,
      endDate: endDate,
      isRecurring: false,
      recurrences: <Recurrence>[],
      description: description,
    );
  }

  factory Habit.recurring({
    required String id,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String? description,
    List<Recurrence>? recurrences,
  }) {
    return Habit(
      id: id,
      name: name,
      startDate: startDate,
      endDate: endDate,
      isRecurring: true,
      recurrences: recurrences ?? <Recurrence>[],
      description: description,
    );
  }

  String get gId => _id;

  String get gName => name;

  DateTime get gStartDate => startDate;

  DateTime get gEndDate => endDate;

  bool get gIsRecurring => isRecurring;

  List<Recurrence> get gRecurrences => recurrences;

  dynamic get gCompleted => _completed;

  Habit addRecurrence(Frequency frequency, [DateTime? startDate]) {
    if (isRecurring == false) {
      throw Exception("Can't add recurrence to a one-time habit");
    }
    recurrences.add(
      Recurrence(freq: frequency, startDate: startDate ?? this.startDate),
    );
    return this;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': _id,
      'name': name,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isRecurring': isRecurring,
      'recurrences': recurrences.map((r) => r.toJson()).toList(),
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    if (json['isRecurring'] == true) {
      final habit = Habit.recurring(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        startDate: DateTime.parse(json['startDate']),
        endDate: DateTime.parse(json['endDate']),
      );
      habit.recurrences.addAll(
        json['recurrences']
            .map<Recurrence>(
              (r) => Recurrence.fromJson(Map<String, dynamic>.from(r)),
            )
            .toList(),
      );
      return habit;
    } else {
      return Habit.oneTime(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        startDate: DateTime.parse(json['startDate']),
        endDate: DateTime.parse(json['endDate']),
      );
    }
  }

  void complete() {
    //updateTimeStamps(DateTime.now());
  }
}

Future<void> saveHabit(Habit habit) async {
  await saveData('Habits', habit.gId, habit.toJson());
}

Future<Habit> loadHabit(String id) async {
  final data = await loadData('Habits', id);
  return Habit.fromJson(Map<String, dynamic>.from(data));
}

Future<void> deleteHabit(String id) async {
  await deleteData('Habits', id);
}

Future<void> changeHabit(
  String id, {
  String? name,
  String? description,
  DateTime? startDate,
  DateTime? endDate,
  bool? isRecurring,
}) async {
  Habit habit = await loadHabit(id);
  if (name != null) {
    habit.name = name;
  }
  if (description != null) {
    habit.description = description;
  }
  if (startDate != null) {
    habit.startDate = startDate;
  }
  if (endDate != null) {
    habit.endDate = endDate;
  }
  if (isRecurring != null) {
    habit.isRecurring = isRecurring;
  }
  await saveHabit(habit);
}

Future<List<DateTime>> getHabitDates(String id, DateTime limit) async {
  Habit habit = await loadHabit(id);
  if (habit.isRecurring == false) {
    return [habit.startDate];
  }
  bool end = false;

  List<DateTime> dates = [];
  for (Recurrence recurrence in habit.recurrences) {
    switch (recurrence.freq) {
      case Frequency.daily:
        DateTime nextDate = DateTime(
          habit.startDate.year,
          habit.startDate.month,
          habit.startDate.day,
          recurrence.startDate.hour,
          recurrence.startDate.minute,
        );
        end = false;
        var numDays = 0;

        while (!end) {
          final newDate = nextDate.add(Duration(days: numDays));
          if (newDate.isAfter(habit.endDate) || newDate.isAfter(limit)) {
            end = true;
            break;
          }
          dates.add(newDate);
          numDays++;
        }
        break;
      case Frequency.weekly:
        DateTime nextDate = DateTime(
          habit.startDate.year,
          habit.startDate.month,
          recurrence.startDate.day,
          recurrence.startDate.hour,
          recurrence.startDate.minute,
        );
        end = false;
        var numWeeks = 0;

        while (!end) {
          final newDate = nextDate.add(Duration(days: 7 * numWeeks));
          if (newDate.isAfter(habit.endDate) || newDate.isAfter(limit)) {
            end = true;
            break;
          }
          dates.add(newDate);
          numWeeks++;
        }
        break;
      case Frequency.monthly:
        DateTime nextDate = DateTime(
          habit.startDate.year,
          habit.startDate.month,
          recurrence.startDate.day,
          recurrence.startDate.hour,
          recurrence.startDate.minute,
        );
        end = false;
        var numMonths = 0;

        while (!end) {
          final newDate = Jiffy.parseFromDateTime(
            nextDate,
          ).add(months: numMonths).dateTime;
          if (newDate.isAfter(habit.endDate) || newDate.isAfter(limit)) {
            end = true;
            break;
          }
          dates.add(newDate);
          numMonths++;
        }
        break;
      case Frequency.yearly:
        DateTime nextDate = DateTime(
          habit.startDate.year,
          recurrence.startDate.month,
          recurrence.startDate.day,
          recurrence.startDate.hour,
          recurrence.startDate.minute,
        );
        bool end = false;
        var numYears = 0;

        while (!end) {
          final newDate = Jiffy.parseFromDateTime(
            nextDate,
          ).add(years: numYears).dateTime;
          if (newDate.isAfter(habit.endDate) || newDate.isAfter(limit)) {
            end = true;
            break;
          }
          dates.add(newDate);
          numYears++;
        }
        break;
      default:
        end = true;
        break;
    }
  }
  return dates;
}
