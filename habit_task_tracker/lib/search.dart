import 'package:habit_task_tracker/habit.dart';
import 'package:localstore/localstore.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';

final db = Localstore.instance;
final fuzzyVal = 70; // threshold for fuzzy search

final collectionHabits = db.collection('data/Habits');
final collectionTestHabits = db.collection('data/Habits_test');

Future<List<Habit>> searchHabits({
  DateTime? date1,
  DateTime? date2,
  String? name,
  String? description,
  bool test = false,
}) {
  Future<List<Habit>> results = Future.value([]);
  if (date1 != null && date2 != null) {
    return searchHabitsBetweenDates(date1, date2, test: test);
  } else if (name != null) {
    return searchHabitsByName(name, test: test);
  } else if (description != null) {
    return searchHabitsByDescription(description, test: test);
  } else if (date1 == null &&
      date2 == null &&
      name == null &&
      description == null) {
    return searchAllHabits(test: test);
  }
  return results;
}

Future<List<Habit>> searchHabitsBetweenDates(
  DateTime date1,
  DateTime date2, {
  bool test = false,
}) async {
  List<Habit> results = [];
  final habitsData = await (test
      ? collectionTestHabits.get()
      : collectionHabits.get());
  if (habitsData == null) {
    return results;
  }
  habitsData.forEach((id, data) {
    Habit habit = Habit.fromJson(data);
    if ((habit.startDate.isAfter(date1) ||
            habit.startDate.isAtSameMomentAs(date1)) &&
        (habit.endDate.isBefore(date2) ||
            habit.endDate.isAtSameMomentAs(date2))) {
      results.add(habit);
    }
  });
  return results;
}

Future<List<Habit>> searchHabitsByName(String name, {bool test = false}) async {
  List<Habit> results = [];
  final habitsData = await (test
      ? collectionTestHabits.get()
      : collectionHabits.get());
  if (habitsData == null) {
    return results;
  }
  habitsData.forEach((id, data) {
    Habit habit = Habit.fromJson(data);
    int ratioName = ratio(habit.name.toLowerCase(), name.toLowerCase());
    if (ratioName > fuzzyVal) {
      results.add(habit);
    }
  });
  return results;
}

Future<List<Habit>> searchHabitsByDescription(
  String description, {
  bool test = false,
}) async {
  List<Habit> results = [];
  final habitsData = await (test
      ? collectionTestHabits.get()
      : collectionHabits.get());
  if (habitsData == null) {
    return results;
  }
  habitsData.forEach((id, data) {
    Habit habit = Habit.fromJson(data);
    if (habit.description != null) {
      int ratioDesc = partialRatio(
        habit.description!.toLowerCase(),
        description.toLowerCase(),
      );
      if (ratioDesc > fuzzyVal) {
        results.add(habit);
      }
    }
  });

  return results;
}

Future<List<Habit>> searchAllHabits({bool test = false}) async {
  List<Habit> results = [];
  final habitsData = await (test
      ? collectionTestHabits.get()
      : collectionHabits.get());
  if (habitsData == null) {
    return results;
  }
  habitsData.forEach((id, data) {
    Habit habit = Habit.fromJson(data);
    results.add(habit);
  });
  return results;
}
