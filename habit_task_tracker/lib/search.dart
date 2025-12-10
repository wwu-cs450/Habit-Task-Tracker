import 'package:habit_task_tracker/habit.dart';
import 'package:localstore/localstore.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';

final db = Localstore.instance;
final fuzzyVal = 70; // threshold for fuzzy search
final digitRegex = RegExp(r'\b(\d+)\b');

final collectionHabits = db.collection('data/Habits');
final collectionTestHabits = db.collection('data/Habits_test');

/// Helper function to check if all digits in the query match the candidate text
bool _checkDigitMatch(String query, String candidate) {
  final digitMatches = digitRegex
      .allMatches(query)
      .map((m) => m.group(1)!)
      .toList();

  if (digitMatches.isEmpty) {
    return true;
  }

  final candidateDigits = digitRegex
      .allMatches(candidate)
      .map((m) => m.group(1)!)
      .toList();

  for (final digit in digitMatches) {
    if (!candidateDigits.contains(digit)) {
      return false;
    }
  }

  return true;
}

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

  final q = name.toLowerCase();

  habitsData.forEach((id, data) {
    Habit habit = Habit.fromJson(data);
    final habitName = habit.name.toLowerCase();

    // Check if digits in query match the habit name
    if (!_checkDigitMatch(q, habitName)) {
      return;
    }

    // Check if query is contained in the name
    if (habitName.contains(q)) {
      results.add(habit);
      return;
    }

    // Then apply the fuzzy matching logic
    int ratioName = ratio(habitName, q);
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

  final q = description.toLowerCase();

  habitsData.forEach((id, data) {
    Habit habit = Habit.fromJson(data);
    if (habit.description != null) {
      final habitDesc = habit.description!.toLowerCase();

      // Check if digits in query match the habit description
      if (!_checkDigitMatch(q, habitDesc)) {
        return;
      }

      // Check if query is contained in the description
      if (habitDesc.contains(q)) {
        results.add(habit);
        return;
      }

      // Then apply the fuzzy matching logic
      int ratioDesc = partialRatio(habitDesc, q);
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
