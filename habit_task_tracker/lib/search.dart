import 'package:flutter/cupertino.dart';
import 'package:habit_task_tracker/habit.dart';
// import 'package:habit_task_tracker/log.dart';
import 'package:localstore/localstore.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';


final db = Localstore.instance;
final fuzzyVal = 70; // threshold for fuzzy search

// check if //data/habits exists
final filePath = Directory('data/Habits');
bool exists = filePath.existsSync();
final collectionHabits = exists? db.collection('data/Habits') : null;

Future<List<Habit>> searchHabits({DateTime? date1, DateTime? date2, String? name, String? description}) {
  Future<List<Habit>> results = Future.value([]);
  if (!exists) {
    print('No habits found in the database. in $filePath');
    return results;
  }
  if (date1 != null && date2 != null) {
    return searchHabitsBetweenDates(date1, date2);
  }
  else if (name != null) {
    return searchHabitsByName(name);
  }
  else if (description != null) {
    return searchHabitsByDescription(description);
  }
  return results;
}


Future<List<Habit>> searchHabitsBetweenDates(DateTime date1, DateTime date2) async {
  List<Habit> results = [];
  if (!exists) {
    print('No habits found in the database.');
    return results;
  }
  final habitsData = await collectionHabits?.get();
  if (habitsData == null) {
    print('No habits data found.');
    return results;
  };
  habitsData.forEach((id, data) {
    Habit habit = Habit.fromJson(data);
    if ((habit.startDate.isAfter(date1) || habit.startDate.isAtSameMomentAs(date1)) &&
        (habit.endDate.isBefore(date2) || habit.endDate.isAtSameMomentAs(date2))) {
          results.add(habit);
    }
  });  
  return results;
}

Future<List<Habit>> searchHabitsByName(String name) async {
  List<Habit> results = [];
  if (!exists) {
    print('No habits found in the database.');
    return results;
  }
  final habitsData = await collectionHabits?.get();
  if (habitsData == null) {
    print('No habits data found.');
    return results;
  };
  habitsData.forEach((id, data) {
    Habit habit = Habit.fromJson(data);
    int ratioName = ratio(habit.name.toLowerCase(), name.toLowerCase());
    if (ratioName > fuzzyVal) {
      results.add(habit);
    }
  });
  return results;
}

Future<List<Habit>> searchHabitsByDescription(String description) async {
  List<Habit> results = [];
  if (!exists) {
    print('No habits found in the database.');
    return results;
  }
  final habitsData = await collectionHabits?.get();
  if (habitsData == null) {
    print('No habits data found.');
    return results;
  };
  habitsData.forEach((id, data) {
    Habit habit = Habit.fromJson(data);
    if (habit.description != null) {
      int ratioDesc = partialRatio(habit.description!.toLowerCase(), description.toLowerCase());
      if (ratioDesc > fuzzyVal) {
        results.add(habit);
      }
    }
  });
  
  return results;
}

