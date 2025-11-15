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

List<Habit> searchHabits({DateTime? date1, DateTime? date2, String? name, String? description}) {
  List<Habit> results = [];
  if (!exists) {
    print('No habits found in the database. in $filePath');
    return results;
  }
  if (date1 != null && date2 != null) {
    results.addAll(searchHabitsBetweenDates(date1, date2));
  }
  else if (name != null) {
    results.addAll(searchHabitsByName(name));
  }
  else if (description != null) {
    results.addAll(searchHabitsByDescription(description));
  }
  return results;
}


List<Habit> searchHabitsBetweenDates(DateTime date1, DateTime date2) {
  List<Habit> results = [];
  if (!exists) {
    print('No habits found in the database.');
    return results;
  }
  collectionHabits?.get().then((habitsData) {
    if (habitsData != null) {
      habitsData.forEach((id, data) {
        Habit habit = Habit.fromJson(data);
        if ((habit.startDate.isAfter(date1) || habit.startDate.isAtSameMomentAs(date1)) &&
            (habit.startDate.isBefore(date2) || habit.startDate.isAtSameMomentAs(date2))) {
          results.add(habit);
        }
      });

    }
  });
  return results;
}

List<Habit> searchHabitsByName(String name) {
  List<Habit> results = [];
  if (!exists) {
    print('No habits found in the database.');
    return results;
  }
  collectionHabits?.get().then((habitsData) {
    if (habitsData != null) {
      habitsData.forEach((id, data) {
        Habit habit = Habit.fromJson(data);
        int ratioName = ratio(habit.name.toLowerCase(), name.toLowerCase());
        if (ratioName > fuzzyVal) {
          results.add(habit);
        }
      });
    }
  });
  return results;
}

List<Habit> searchHabitsByDescription(String description) {
  List<Habit> results = [];
  if (!exists) {
    print('No habits found in the database.');
    return results;
  }
  collectionHabits?.get().then((habitsData) {
    if (habitsData != null) {
      habitsData.forEach((id, data) {
        Habit habit = Habit.fromJson(data);
        if (habit.description != null) {
          int ratioDesc = ratio(habit.description!.toLowerCase(), description.toLowerCase());
          if (ratioDesc > fuzzyVal) {
            results.add(habit);
          }
        }
      });
    }
  });
  return results;
}

