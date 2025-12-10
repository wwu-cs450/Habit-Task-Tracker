// taken from https://ejolie.hashnode.dev/developing-ios-android-home-screen-widgets-in-flutter

import 'dart:convert';

import 'package:home_widget/home_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'habit.dart';
import 'log.dart';
import 'uuid.dart';
import 'main.dart' show navigatorKey;
import 'main_helpers.dart'
    show loadHabitsFromDb, setCompletion, isSameDay, showCreateHabitDialog;
import 'state/habit_state.dart';

@pragma('vm:entry-point')
class WidgetService {
  /// iOS
  static const iOSWidgetAppGroupId = 'group.com.example.habitTaskTrackerGroup';
  // todo change name
  static const widgetiOSName = 'HabitWidget';

  /// Android
  static const androidPackagePrefix = 'com.example.habitTaskTracker';
  static const widgetAndroidName =
      '$androidPackagePrefix.receivers.WidgetReceiver';

  /// Called in main.dart
  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(iOSWidgetAppGroupId);
    await HomeWidget.registerInteractivityCallback(interactiveCallback);
  }

  /// Save data to Shared Preferences
  static Future<void> _saveData<T>(String key, T data) async {
    // convert data to json
    final json = jsonEncode(data);
    await HomeWidget.saveWidgetData<String>(key, json.toString());
  }

  /// Request to update widgets on both iOS and Android
  static Future<void> _updateWidget({
    String? iOSWidgetName,
    String? qualifiedAndroidName,
  }) async {
    final result = await HomeWidget.updateWidget(
      name: iOSWidgetName,
      iOSName: iOSWidgetName,
      qualifiedAndroidName: qualifiedAndroidName,
    );
    debugPrint(
      '[WidgetService.updateWidget] iOSWidgetName: $iOSWidgetName, qualifiedAndroidName: $qualifiedAndroidName, result: $result',
    );
  }

  static Future<void> _complete(String habitId) async {
    // find habit by id
    final habit = await loadHabit(habitId);

    // if (habit.completedDates.any((d) => isSameDay(d, DateTime.now()))) {
    //   return;
    // }
    final completed = await setCompletion(
      Uuid.fromString(habitId),
      true,
      habit.description,
    );

    if (!completed) {
      throw Exception('Failed to complete habit');
    }

    syncHabitsToWidget().catchError((e) {
      debugPrint('Error syncing habits to widget after completion: $e');
    });
  }

  static Future<void> _uncomplete(String habitId) async {
    // find habit by id
    final habit = await loadHabit(habitId);

    if (!habit.gCompleted) {
      return;
    }

    final completed = await setCompletion(
      Uuid.fromString(habitId),
      false,
      habit.description,
    );

    if (!completed) {
      throw Exception('Failed to uncomplete habit with id $habitId');
    }

    await _updateWidget(
      iOSWidgetName: widgetiOSName,
      qualifiedAndroidName: widgetAndroidName,
    );
  }

  /// Check if a habit is completed for a specific day
  static Future<bool> _isCompletedForDay(String habitId, DateTime day) async {
    try {
      final log = await loadLog(Uuid.fromString(habitId));
      return log.gTimeStamps.any((dt) => isSameDay(dt, day));
    } catch (_) {
      return false;
    }
  }

  /// Sync habit data to the widget (ID, name, completion status)
  /// This should be called when habits are created, updated, or when app lifecycle changes
  static Future<void> syncHabitsToWidget() async {
    try {
      // Load all habits from database
      final result = await loadHabitsFromDb();
      final List<Habit> habits = (result['habits'] as List<dynamic>)
          .cast<Habit>();
      final now = DateTime.now();

      // Prepare habit data for widget
      final List<Map<String, dynamic>> habitData = [];

      for (final habit in habits) {
        // Check completion status for today
        final isCompleted = await _isCompletedForDay(habit.gId, now);

        habitData.add({
          'id': habit.gId,
          'name': habit.name,
          'isCompleted': isCompleted,
        });
      }

      // Save habit data to widget
      await _saveData<List<Map<String, dynamic>>>('habits', habitData);

      // Also save count for convenience
      await _saveData<int>('habitCount', habitData.length);

      // Update the widget
      await _updateWidget(
        iOSWidgetName: widgetiOSName,
        qualifiedAndroidName: widgetAndroidName,
      );

      debugPrint(
        '[WidgetService.syncHabitsToWidget] Synced ${habitData.length} habits to widget',
      );
    } catch (e) {
      debugPrint('[WidgetService.syncHabitsToWidget] Error syncing habits: $e');
    }
  }

  @pragma('vm:entry-point')
  static Future<void> interactiveCallback(Uri? uri) async {
    // We check the host of the uri to determine which action should be triggered.
    debugPrint('[WidgetService.interactiveCallback] uri: $uri');
    if (uri?.host == 'complete') {
      // grab id query param
      final id = uri?.queryParameters['id'];
      if (id == null) {
        return;
      }
      await _complete(id);
      // Sync after completion to update widget
      await syncHabitsToWidget();
    } else if (uri?.host == 'uncomplete') {
      final id = uri?.queryParameters['id'];
      if (id == null) {
        return;
      }
      await _uncomplete(id);
      // Sync after uncompletion to update widget
      await syncHabitsToWidget();
    } else if (uri?.host == 'task:add') {
      final context = navigatorKey.currentContext;
      if (context == null) {
        debugPrint(
          '[WidgetService.interactiveCallback] Cannot open dialog: context is null (app may not be running)',
        );
        return;
      }
      // this should trigger the add task widget
      await showCreateHabitDialog(context, (habit) async {
        // Add habit to state if available
        if (context.mounted) {
          try {
            final habitState = context.read<HabitState>();
            await habitState.addHabit(habit);
          } catch (e) {
            debugPrint(
              '[WidgetService.interactiveCallback] Failed to add habit to state: $e',
            );
          }
        }
        // sync to widget
        await syncHabitsToWidget();
      });
    }
  }
}
