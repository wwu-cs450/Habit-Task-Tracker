import 'package:habit_task_tracker/backend.dart';
import 'package:habit_task_tracker/log.dart';
import 'package:habit_task_tracker/notifier.dart' as notifier;
import 'package:duration/duration.dart';
import 'package:logger/logger.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:habit_task_tracker/recurrence.dart';
import 'package:jiffy/jiffy.dart';

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
  List<Recurrence> recurrences;
  Log log;
  List<DateTime> completedDates;
  List<notifier.Notification> notifications;
  // Should only be accessed from the main isolate
  // for thread safety
  static final Map<String, Habit> _habitCache = {};
  static final logger = Logger();
  factory Habit({
    required String id,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required bool isRecurring,
    required List<Recurrence> recurrences,
    List<DateTime>? completedDates,

    /// If true, do not use the cached Habit instance for this id.
    bool? skipCache,
    String? description,
  }) {
    if (_habitCache.containsKey(id) && skipCache != true) {
      return _habitCache[id]!;
    }
    final habit = Habit._internal(
      id: id,
      name: name,
      startDate: startDate,
      endDate: endDate,
      isRecurring: isRecurring,
      recurrences: recurrences,
      description: description,
      notifications: [],
    );
    _habitCache[id] = habit;
    return habit;
  }
  static Habit? fromId(String id) {
    return _habitCache[id];
  }

  Habit._internal({
    required String id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.isRecurring,
    required this.recurrences,
    this.description,
    required this.notifications,
    List<DateTime>? completedDates, // optional in constructor
  }) : _id = id,
       log = createLog(id, description),
       completedDates = completedDates ?? [];

  factory Habit.oneTime({
    required String id,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String? description,
  }) {
    return Habit(
      id: id,
      name: name,
      startDate: startDate,
      endDate: endDate,
      isRecurring: false,
      recurrences: <Recurrence>[],
      description: description,
    );
  }

  factory Habit.recurring({
    required String id,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String? description,
    List<Recurrence>? recurrences,
  }) {
    return Habit(
      id: id,
      name: name,
      startDate: startDate,
      endDate: endDate,
      isRecurring: true,
      recurrences: recurrences ?? <Recurrence>[],
      description: description,
    );
  }

  String get gId => _id;
  String get gName => name;
  DateTime get gStartDate => startDate;
  DateTime get gEndDate => endDate;
  bool get gIsRecurring => isRecurring;

  List<Recurrence> get gRecurrences => recurrences;

  dynamic get gCompleted => _completed;

  Habit addRecurrence(Frequency frequency, [DateTime? startDate]) {
    if (isRecurring == false) {
      throw Exception("Can't add recurrence to a one-time habit");
    }
    recurrences.add(
      Recurrence(freq: frequency, startDate: startDate ?? this.startDate),
    );
    return this;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': _id,
      'name': name,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isRecurring': isRecurring,
      'recurrences': recurrences.map((r) => r.toJson()).toList(),
      'completedDates': completedDates.map((d) => d.toIso8601String()).toList(),
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      isRecurring: json['isRecurring'],
      recurrences:
          (json['recurrences'] as List<dynamic>?)
              ?.map<Recurrence>(
                (r) => Recurrence.fromJson(Map<String, dynamic>.from(r)),
              )
              .toList() ??
          [],
      completedDates: (json['completedDates'] as List<dynamic>?)
          ?.map((e) => DateTime.parse(e))
          .toList(),
    )
    // Following line can be uncommented once
    // `withNotification()` is idempotent.
    // For now, behavior is unchanged
    // .withNotification()
    ;
  }
  // Schedule notification for a habit. Automatically
  // handles scheduling, recurrence, etc. This function
  // is not idempotent *yet*; that's a stretch goal.
  //
  // Intended to be used like this:
  //   final habit = Habit(...).withNotification();
  Habit withNotification({
    Duration reminderLeadTime = const Duration(hours: 1),
  }) {
    // Ensure that startDate is in the future
    // Might be smart to do this in the initializer
    final DateTime notifDateTime = _earliestDate(
      startDate.add(reminderLeadTime), // Task time - lead time
      DateTime.now().add(
        Duration(seconds: 1),
      ), // At least 1 second in the future
    );
    final notification = notifier.Notification(
      this,
      'Reminder for $name',
      'Don\'t forget to complete your habit!\nIt\'s due in ${reminderLeadTime.pretty(abbreviated: false)}.',
    );
    notifications.add(notification);
    // `Notification.showScheduled` handles recurrences automatically
    notification.showScheduled(notifDateTime).catchError((e, stack) {
      logger.e('Failed to schedule notification for habit with ID $gId: $e');
    });
    return this;
  }

  DateTime _earliestDate(DateTime a, DateTime b) {
    return a.isBefore(b) ? a : b;
  }

  void complete([DateTime? day]) {
    final d = day ?? DateTime.now();
    if (!completedDates.any((x) => isSameDay(x, d))) {
      completedDates.add(d);
    }
  }

  // void complete() {
  //updateTimeStamps(DateTime.now());
}
// }

Future<void> saveHabit(Habit habit) async {
  await saveData('Habits', habit.gId, habit.toJson());
}

Future<void> saveTestHabit(Habit habit) async {
  await saveData('Habits_test', habit.gId, habit.toJson());
}

Future<Habit> loadHabit(String id) async {
  final data = await loadData('Habits', id);
  return Habit.fromJson(Map<String, dynamic>.from(data));
}

Future<Habit> loadTestHabit(String id) async {
  final data = await loadData('Habits_test', id);
  return Habit.fromJson(Map<String, dynamic>.from(data));
}

Future<void> deleteHabit(String id) async {
  await deleteData('Habits', id);
}

Future<void> deleteTestHabit(String id) async {
  await deleteData('Habits_test', id);
}

Future<void> changeHabit(
  String id, {
  String? name,
  String? description,
  DateTime? startDate,
  DateTime? endDate,
  bool? isRecurring,
  bool test = false,
}) async {
  Habit habit = (test ? await loadTestHabit(id) : await loadHabit(id));
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
  test ? await saveTestHabit(habit) : await saveHabit(habit);
}

Future<List<DateTime>> getHabitDates(
  String id,
  DateTime limit, {
  bool test = false,
}) async {
  Habit habit = test ? await loadTestHabit(id) : await loadHabit(id);
  if (habit.isRecurring == false) {
    return [habit.startDate];
  }
  bool end = false;

  List<DateTime> dates = [];
  for (Recurrence recurrence in habit.recurrences) {
    switch (recurrence.freq) {
      case Frequency.daily:
        DateTime nextDate = DateTime(
          habit.startDate.year,
          habit.startDate.month,
          habit.startDate.day,
          recurrence.startDate.hour,
          recurrence.startDate.minute,
        );
        end = false;
        var numDays = 0;

        while (!end) {
          final newDate = nextDate.add(Duration(days: numDays));
          if (newDate.isAfter(habit.endDate) || newDate.isAfter(limit)) {
            end = true;
            break;
          }
          dates.add(newDate);
          numDays++;
        }
        break;
      case Frequency.weekly:
        DateTime nextDate = DateTime(
          habit.startDate.year,
          habit.startDate.month,
          recurrence.startDate.day,
          recurrence.startDate.hour,
          recurrence.startDate.minute,
        );
        end = false;
        var numWeeks = 0;

        while (!end) {
          final newDate = nextDate.add(Duration(days: 7 * numWeeks));
          if (newDate.isAfter(habit.endDate) || newDate.isAfter(limit)) {
            end = true;
            break;
          }
          dates.add(newDate);
          numWeeks++;
        }
        break;
      case Frequency.monthly:
        DateTime nextDate = DateTime(
          habit.startDate.year,
          habit.startDate.month,
          recurrence.startDate.day,
          recurrence.startDate.hour,
          recurrence.startDate.minute,
        );
        end = false;
        var numMonths = 0;

        while (!end) {
          final newDate = Jiffy.parseFromDateTime(
            nextDate,
          ).add(months: numMonths).dateTime;
          if (newDate.isAfter(habit.endDate) || newDate.isAfter(limit)) {
            end = true;
            break;
          }
          dates.add(newDate);
          numMonths++;
        }
        break;
      case Frequency.yearly:
        DateTime nextDate = DateTime(
          habit.startDate.year,
          recurrence.startDate.month,
          recurrence.startDate.day,
          recurrence.startDate.hour,
          recurrence.startDate.minute,
        );
        end = false;
        var numYears = 0;

        while (!end) {
          final newDate = Jiffy.parseFromDateTime(
            nextDate,
          ).add(years: numYears).dateTime;
          if (newDate.isAfter(habit.endDate) || newDate.isAfter(limit)) {
            end = true;
            break;
          }
          dates.add(newDate);
          numYears++;
        }
        break;
      default:
        end = true;
        break;
    }
  }
  return dates;
}
