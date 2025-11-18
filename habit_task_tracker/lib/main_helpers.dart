import 'package:habit_task_tracker/backend.dart';
import 'package:habit_task_tracker/habit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habit_task_tracker/log.dart';

// I got help from Copilot to write the following functions.

/// Load habits from the DB and their status for today
Future<Map<String, dynamic>> loadHabitsFromDb() async {
  final Map<String, dynamic>? all = await db.collection('data/Habits').get();
  final List<Habit> list = <Habit>[];
  final List<bool> loadedCompleted = <bool>[];
  if (all != null) {
    for (final entry in all.entries) {
      final String id = entry.key;
      final Map<String, dynamic> rawMap = Map<String, dynamic>.from(
        entry.value,
      );
      // Determine if habit was completed today
      try {
        final Habit habit = await loadHabit(id);
        list.add(habit);
        bool completedToday = false;
        try {
          final l = await loadLog(habit.gId);
          final now = DateTime.now();
          completedToday = l.gTimeStamps.any(
            (dt) =>
                dt.year == now.year &&
                dt.month == now.month &&
                dt.day == now.day,
          );
        } catch (_) {
          completedToday = false;
        }
        loadedCompleted.add(completedToday);
      } catch (e) {
        // Load from JSON if load habit method failed
        try {
          final Habit habit = Habit.fromJson(rawMap);
          list.add(habit);
          bool completedToday = false;
          try {
            final l = await loadLog(habit.gId);
            final now = DateTime.now();
            completedToday = l.gTimeStamps.any(
              (dt) =>
                  dt.year == now.year &&
                  dt.month == now.month &&
                  dt.day == now.day,
            );
          } catch (_) {
            completedToday = false;
          }
          loadedCompleted.add(completedToday);
        } catch (err) {
          debugPrint('Failed to load/parse habit $id: $e / $err');
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

/// Shows a confirm deletion dialog and deletes the habit if confirmed.
Future<void> deleteHabitWithConfirmation(
  BuildContext context,
  Habit habit,
  Future<void> Function(String habitId) onDeleteUI,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete item?'),
      content: const Text('Are you sure you want to delete this item?'),
      // Remove dialog from the display with a boolean result
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  try {
    await onDeleteUI(habit.gId);
  } catch (e) {
    debugPrint('UI deletion callback failed for ${habit.gId}: $e');
    return;
  }

  // Try to delete the habit from the database
  try {
    await deleteHabit(habit.gId);
  } catch (e) {
    debugPrint('Failed to delete habit ${habit.gId}: $e');
  }
}

// THIS COULD LIKELY BE MOVED TO HABIT.DART
/// Create a Habit and save it
Future<Habit> createAndPersistHabit(
  String title,
  String description, {
  DateTime? startDate,
  DateTime? endDate,
  bool isRecurring = false,
  Frequency? frequency,
}) async {
  final id = DateTime.now().millisecondsSinceEpoch.toString();
  final DateTime s = startDate ?? DateTime.now();
  final DateTime e = endDate ?? s.add(const Duration(days: 1));
  final Frequency effectiveFrequency = isRecurring
      ? (frequency ?? Frequency.daily)
      : (frequency ?? Frequency.none);

  final habit = Habit(
    id: id,
    name: title,
    description: description,
    startDate: s,
    endDate: e,
    isRecurring: isRecurring,
    frequency: effectiveFrequency,
  );

  final Map<String, dynamic> m = habit.toJson();
  await db.collection('data/Habits').doc(id).set(m);
  return habit;
}

/// Show the create-habit dialog and save the habit if confirmed.
Future<void> showCreateHabitDialog(
  BuildContext context,
  Future<void> Function(Habit habit) onCreated,
) async {
  final titleController = TextEditingController();
  final descController = TextEditingController();
  final dateController = TextEditingController();
  final endDateController = TextEditingController();
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  bool selectedRecurring = false;
  Frequency selectedFrequency = Frequency.daily;

  String formatDate(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day'.replaceFirst('\u007f', '');
  }

  // initialize with start date today and end date tomorrow
  selectedStartDate = DateTime.now();
  selectedEndDate = selectedStartDate.add(const Duration(days: 1));
  dateController.text = formatDate(selectedStartDate);
  endDateController.text = formatDate(selectedEndDate);

  final saved = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    useRootNavigator: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('New Habit'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title field
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    autofocus: false,
                  ),
                  const SizedBox(height: 12),
                  // Description field
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    keyboardType: TextInputType.multiline,
                    minLines: 1,
                    maxLines: 3,
                    textAlignVertical: TextAlignVertical.top,
                  ),
                  const SizedBox(height: 12),
                  // Recurring toggle
                  Row(
                    children: [
                      const Text('Recurring'),
                      const Spacer(),
                      Switch(
                        value: selectedRecurring,
                        onChanged: (v) {
                          setState(() {
                            selectedRecurring = v;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Frequency selector visible only if recurring
                  if (selectedRecurring)
                    Row(
                      children: [
                        const Text('Frequency'),
                        const SizedBox(width: 12),
                        DropdownButton<Frequency>(
                          value: selectedFrequency,
                          items: const [
                            DropdownMenuItem(
                              value: Frequency.daily,
                              child: Text('Daily'),
                            ),
                            DropdownMenuItem(
                              value: Frequency.weekly,
                              child: Text('Weekly'),
                            ),
                            DropdownMenuItem(
                              value: Frequency.monthly,
                              child: Text('Monthly'),
                            ),
                            DropdownMenuItem(
                              value: Frequency.yearly,
                              child: Text('Yearly'),
                            ),
                          ],
                          onChanged: (f) {
                            if (f == null) return;
                            setState(() {
                              selectedFrequency = f;
                            });
                          },
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  // Start date field
                  TextField(
                    controller: dateController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Start date'),
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedStartDate ?? now,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(now.year + 5),
                      );
                      if (picked != null) {
                        selectedStartDate = picked;
                        dateController.text = formatDate(picked);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  // End date field
                  TextField(
                    controller: endDateController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'End date'),
                    onTap: () async {
                      final now = DateTime.now();
                      final init =
                          selectedEndDate ??
                          (selectedStartDate ?? now).add(
                            const Duration(days: 1),
                          );
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: init,
                        firstDate: selectedStartDate ?? DateTime(2000),
                        lastDate: DateTime(now.year + 5),
                      );
                      if (picked != null) {
                        selectedEndDate = picked;
                        endDateController.text = formatDate(picked);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final navigator = Navigator.of(context, rootNavigator: true);
                  FocusManager.instance.primaryFocus?.unfocus();
                  try {
                    await SystemChannels.textInput.invokeMethod(
                      'TextInput.hide',
                    );
                  } catch (_) {}
                  await Future.delayed(const Duration(milliseconds: 150));
                  navigator.pop(false);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final navigator = Navigator.of(context, rootNavigator: true);
                  FocusManager.instance.primaryFocus?.unfocus();
                  try {
                    await SystemChannels.textInput.invokeMethod(
                      'TextInput.hide',
                    );
                  } catch (_) {}
                  await Future.delayed(const Duration(milliseconds: 150));
                  navigator.pop(true);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );

  if (saved == true) {
    final title = titleController.text.isEmpty
        ? 'New Habit'
        : titleController.text.trim();
    final desc = descController.text.trim();
    try {
      // Ensure that end date is on or after start date
      if (selectedStartDate != null &&
          selectedEndDate != null &&
          selectedEndDate!.isBefore(selectedStartDate!)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('End date must be the same or after start date'),
            ),
          );
        }
        return;
      }

      final habit = await createAndPersistHabit(
        title,
        desc.isEmpty ? 'Description' : desc,
        startDate: selectedStartDate,
        endDate: selectedEndDate,
        isRecurring: selectedRecurring,
        frequency: selectedRecurring ? selectedFrequency : Frequency.none,
      );
      await onCreated(habit);
    } catch (e) {
      debugPrint('Failed to create habit: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to create habit')));
      }
    }
  }

  titleController.dispose();
  descController.dispose();
  dateController.dispose();
  endDateController.dispose();
}

// Convert Frequency value to a string
String frequencyToString(Frequency f) {
  switch (f) {
    case Frequency.daily:
      return 'Daily';
    case Frequency.weekly:
      return 'Weekly';
    case Frequency.monthly:
      return 'Monthly';
    case Frequency.yearly:
      return 'Yearly';
    case Frequency.none:
      return 'None';
  }
}

/// Check if two DateTime objects represent the same day
bool isSameDay(DateTime a, DateTime b) {
  final la = a.toLocal();
  final lb = b.toLocal();
  return la.year == lb.year && la.month == lb.month && la.day == lb.day;
}

/// Persist completion state for a habit for "today".
Future<bool> setCompletion(
  String habitId,
  bool completed,
  String? description,
) async {
  final now = DateTime.now();
  try {
    if (completed) {
      try {
        final existingLog = await loadLog(habitId);
        final exists = existingLog.gTimeStamps.any((dt) => isSameDay(dt, now));
        if (!exists) {
          existingLog.timeStamps.add(now);
          await saveLog(existingLog);
        }
      } catch (_) {
        // No existing log so create one and add timestamp
        final l = createLog(habitId, description);
        await l.updateTimeStamps(now);
      }
    } else {
      try {
        final existingLog = await loadLog(habitId);
        existingLog.timeStamps.removeWhere((dt) => isSameDay(dt, now));
        if (existingLog.timeStamps.isEmpty) {
          await deleteData('Logs', habitId);
        } else {
          await saveLog(existingLog);
        }
      } catch (_) {
        // nothing to remove — treat as success
      }
    }
    return true;
  } catch (e) {
    debugPrint('Failed to persist completion for $habitId: $e');
    return false;
  }
}
