import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:habit_task_tracker/backend.dart';
import 'package:habit_task_tracker/log.dart';
import 'package:habit_task_tracker/frequency.dart';

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
  Frequency? frequency;
  List<DateTime>? intervals;
  Log log;

  Habit._({
    required String id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.isRecurring,
    this.description,
  }) : _id = id,
       log = createLog(id, description);

  factory Habit.oneTime({
    required String id,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String? description,
    bool isRecurring = false,
  }) {
    return Habit._(
      id: id,
      name: name,
      startDate: startDate,
      endDate: endDate,
      isRecurring: isRecurring,
      description: description,
    );
  }

  factory Habit.recurring({
    required String id,
    required String name,
    required Frequency frequency,
    List<DateTime>? intervals,
    String? description,
    required DateTime startDate,
    required DateTime endDate,
    bool isRecurring = true,
  }) {
    Habit habit = Habit._(
      id: id,
      name: name,
      startDate: startDate,
      endDate: endDate,
      isRecurring: isRecurring,
      description: description,
    );
    habit.frequency = frequency;
    habit.intervals = intervals ?? [DateTime.now()];
    return habit;
  }

  String get gId => _id;

  String get gName => name;

  DateTime get gStartDate => startDate;

  DateTime get gEndDate => endDate;

  bool get gIsRecurring => isRecurring;

  Frequency get gFrequency => frequency ?? Frequency.none;

  dynamic get gCompleted => _completed;

  Map<String, dynamic> toJson() {
    return {
      'id': _id,
      'name': name,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isRecurring': isRecurring,
      'frequency': gFrequency.toString(),
      'intervals': intervals?.map((e) => e.toIso8601String()).toList(),
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    if (json['isRecurring'] == true) {
      return Habit.recurring(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        startDate: DateTime.parse(json['startDate']),
        endDate: DateTime.parse(json['endDate']),
        isRecurring: json['isRecurring'],
        frequency: frequencyMap[json['frequency']] ?? Frequency.none,
        intervals: (json['intervals'] as List<dynamic>?)
            ?.map((e) => DateTime.parse(e as String))
            .toList(),
      );
    } else {
      return Habit.oneTime(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        startDate: DateTime.parse(json['startDate']),
        endDate: DateTime.parse(json['endDate']),
        isRecurring: json['isRecurring'],
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
  Frequency? frequency,
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
  if (frequency != null) {
    habit.frequency = frequency;
  }
  await saveHabit(habit);
}

Future<List<DateTime>> getHabitDates(String id, DateTime limit) async {

  Habit habit = await loadHabit(id);
  if (habit.isRecurring == false) {
    return [habit.startDate];
  }
  List<DateTime> dates = [];
  bool end = true;
  int totalDays = 0;
  int totalMonths = 0;
  int totalYears = 0;

while (end) {
    switch (habit.frequency) {
      case Frequency.daily:
        for (DateTime date in habit.intervals!) {
          DateTime nextDate = DateTime(
            habit.startDate.year,
            habit.startDate.month,
            habit.startDate.day,
            date.hour,
            date.minute,
          );
          nextDate = nextDate.add(Duration(days: totalDays));
          if (nextDate.isAfter(habit.endDate) || nextDate.isAfter(limit)) {
            end = false;
            break;
          }
          dates.add(nextDate);
        }
        totalDays += 1;
        break;
      case Frequency.weekly:
        for (DateTime date in habit.intervals!) {
          DateTime nextDate = DateTime(
            habit.startDate.year,
            habit.startDate.month,
            date.day,
            date.hour,
            date.minute,
          );
          nextDate = nextDate.add(Duration(days: totalDays));
          if (nextDate.isAfter(habit.endDate) || nextDate.isAfter(limit)) {
            end = false;
            break;
          }
          dates.add(nextDate);
        }
        totalDays += 7;
        break;
      case Frequency.monthly:
        for (DateTime date in habit.intervals!) {
          DateTime nextDate = DateTime(
            habit.startDate.year,
            habit.startDate.month,
            date.day,
            date.hour,
            date.minute,
          );
          var month = nextDate.month;
          var year = nextDate.year;
          if (month == 12) {
            month = 1;
            year += 1;
          } else {
            month += totalMonths;
          }
          nextDate = DateTime(
            year,
            month,
            nextDate.day,
            nextDate.hour,
            nextDate.minute,
          );
          if (nextDate.isAfter(habit.endDate) || nextDate.isAfter(limit)) {
            end = false;
            break;
          }
          dates.add(nextDate);
        }
        totalMonths += 1;
        break;
      case Frequency.yearly:
        for (DateTime date in habit.intervals!) {
          DateTime nextDate = DateTime(
            habit.startDate.year,
            date.month,
            date.day,
            date.hour,
            date.minute,
          );
          nextDate = DateTime(
            nextDate.year + totalYears,
            nextDate.month,
            nextDate.day,
            nextDate.hour,
            nextDate.minute,
          );
          if (nextDate.isAfter(habit.endDate) || nextDate.isAfter(limit)) {
            end = false;
            break;
          }
          dates.add(nextDate);
        }
        totalYears += 1;
        break;
      default:
        break;
    }
    

  } 
  return dates;
}
