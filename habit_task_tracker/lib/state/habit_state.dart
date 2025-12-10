import 'package:flutter/foundation.dart';
import 'package:habit_task_tracker/habit.dart';
import 'package:habit_task_tracker/repository/habit_repository.dart';
import 'package:habit_task_tracker/widget.dart';

/// Manages habit state and notifies listeners of changes
/// This is the single source of truth for habit data in the app
class HabitState extends ChangeNotifier {
  final HabitRepository _repository = HabitRepository();

  List<Habit> _habits = [];
  Set<String> _completedToday = {};
  bool _isLoading = false;
  String? _error;

  List<Habit> get habits => List.unmodifiable(_habits);
  Set<String> get completedToday => Set.unmodifiable(_completedToday);
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get progress {
    if (_habits.isEmpty) return 0.0;
    return _completedToday.length / _habits.length;
  }

  /// Load habits from repository
  Future<void> loadHabits({DateTime? forDate, bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final result = await _repository.loadHabits(forDate: forDate);
      _habits = (result['habits'] as List<dynamic>).cast<Habit>();
      _completedToday = (result['completedIds'] as Set<dynamic>).cast<String>();
      _error = null;

      // Sync to widget after loading
      WidgetService.syncHabitsToWidget().catchError((e) {
        debugPrint('Error syncing to widget: $e');
      });
    } catch (e) {
      _error = 'Failed to load habits: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle completion status for a habit
  Future<bool> toggleCompletion(String habitId, bool completed) async {
    try {
      final success = await _repository.setCompletionStatus(habitId, completed);

      if (success) {
        // Update local state
        if (completed) {
          _completedToday.add(habitId);
        } else {
          _completedToday.remove(habitId);
        }
        notifyListeners();

        // Sync to widget
        WidgetService.syncHabitsToWidget().catchError((e) {
          debugPrint('Error syncing to widget: $e');
        });
      }

      return success;
    } catch (e) {
      debugPrint('Failed to toggle completion: $e');
      return false;
    }
  }

  /// Add a new habit
  Future<void> addHabit(Habit habit) async {
    _habits.insert(0, habit);
    notifyListeners();

    // Sync to widget
    WidgetService.syncHabitsToWidget().catchError((e) {
      debugPrint('Error syncing to widget: $e');
    });
  }

  /// Remove a habit
  Future<void> removeHabit(String habitId) async {
    _habits.removeWhere((h) => h.gId == habitId);
    _completedToday.remove(habitId);
    notifyListeners();

    // Sync to widget
    WidgetService.syncHabitsToWidget().catchError((e) {
      debugPrint('Error syncing to widget: $e');
    });
  }

  /// Refresh habits from database (useful when app resumes)
  Future<void> refresh() async {
    await loadHabits(silent: false);
  }
}
