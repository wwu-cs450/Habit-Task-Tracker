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
  
  final q = name.toLowerCase();
  final digitRegex = RegExp(r'\b(\d+)\b');
  final digitMatches =
      digitRegex.allMatches(q).map((m) => m.group(1)!).toList();
  
  habitsData.forEach((id, data) {
    Habit habit = Habit.fromJson(data);
    final habitName = habit.name.toLowerCase();
    
    // If query contains digits, require exact digit matching first
    if (digitMatches.isNotEmpty) {
      final candidateDigits = digitRegex
          .allMatches(habitName)
          .map((m) => m.group(1)!)
          .toList();
      
      bool allDigitsMatch = true;
      for (final d in digitMatches) {
        if (!candidateDigits.contains(d)) {
          allDigitsMatch = false;
          break;
        }
      }
      
      if (!allDigitsMatch) {
        return;
      }
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
  final digitRegex = RegExp(r'\b(\d+)\b');
  final digitMatches =
      digitRegex.allMatches(q).map((m) => m.group(1)!).toList();
  
  habitsData.forEach((id, data) {
    Habit habit = Habit.fromJson(data);
    if (habit.description != null) {
      final habitDesc = habit.description!.toLowerCase();
      
      // If query contains digits, require exact digit matching first
      if (digitMatches.isNotEmpty) {
        final candidateDigits = digitRegex
            .allMatches(habitDesc)
            .map((m) => m.group(1)!)
            .toList();
        
        bool allDigitsMatch = true;
        for (final d in digitMatches) {
          if (!candidateDigits.contains(d)) {
            allDigitsMatch = false;
            break;
          }
        }
        
        if (!allDigitsMatch) {
          return;
        }
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
