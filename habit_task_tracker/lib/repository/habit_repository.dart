import 'package:habit_task_tracker/backend.dart';
import 'package:habit_task_tracker/habit.dart';
import 'package:habit_task_tracker/log.dart';
import 'package:habit_task_tracker/main_helpers.dart';
import 'package:flutter/foundation.dart';

/// Repository for habit data operations
/// Encapsulates all database operations related to habits
class HabitRepository {
  /// Load all habits with their completion status for a specific day
  Future<Map<String, dynamic>> loadHabits({DateTime? forDate}) async {
    final date = forDate ?? DateTime.now();
    final Map<String, dynamic>? all = await db.collection('data/Habits').get();
    final List<Habit> list = <Habit>[];
    final List<bool> loadedCompleted = <bool>[];

    if (all != null) {
      for (final entry in all.entries) {
        final String id = entry.key;
        final Map<String, dynamic> rawMap = Map<String, dynamic>.from(
          entry.value,
        );
        try {
          final Habit habit = await loadHabit(id);
          list.add(habit);
          final bool completed = await _isCompletedForDate(habit, date);
          loadedCompleted.add(completed);
        } catch (e) {
          // If loadHabit fails, attempt a JSON parse fallback.
          try {
            final Habit habit = Habit.fromJson(rawMap);
            list.add(habit);
            final bool completed = await _isCompletedForDate(habit, date);
            loadedCompleted.add(completed);
          } catch (err) {
            debugPrint(
              'Failed to load habit $id. loadHabit() error: $e; fromJson() error: $err',
            );
          }
        }
      }
    }

    // Match habits with their completed status, then sort them so newest is first
    final List<MapEntry<Habit, bool>> paired = <MapEntry<Habit, bool>>[];
    for (var i = 0; i < list.length; i++) {
      paired.add(
        MapEntry(
          list[i],
          i < loadedCompleted.length ? loadedCompleted[i] : false,
        ),
      );
    }
    paired.sort((a, b) => b.key.startDate.compareTo(a.key.startDate));

    final List<Habit> habits = paired.map((e) => e.key).toList();
    final Set<String> completedIds = <String>{};
    for (var e in paired) {
      if (e.value) completedIds.add(e.key.gId);
    }

    return {'habits': habits, 'completedIds': completedIds};
  }

  /// Set completion status for a habit on a specific date
  Future<bool> setCompletionStatus(
    String habitId,
    bool completed, {
    DateTime? date,
    String? description,
  }) async {
    // Note: date parameter is reserved for future use
    // Currently setCompletion uses DateTime.now() internally
    return await setCompletion(habitId, completed, description);
  }

  /// Check if a habit is completed for a specific date
  Future<bool> _isCompletedForDate(Habit habit, DateTime date) async {
    try {
      final log = await loadLog(habit.gId);
      return log.gTimeStamps.any((dt) => isSameDay(dt, date));
    } catch (_) {
      return false;
    }
  }

  /// Create and persist a new habit
  Future<Habit> createHabit(
    String title,
    String description, {
    DateTime? startDate,
    DateTime? endDate,
    bool isRecurring = false,
    Frequency? frequency,
  }) async {
    return await createAndPersistHabit(
      title,
      description,
      startDate: startDate,
      endDate: endDate,
      isRecurring: isRecurring,
      frequency: frequency,
    );
  }

  /// Delete a habit
  Future<void> deleteHabitById(String habitId) async {
    await deleteHabit(habitId);
  }
}
