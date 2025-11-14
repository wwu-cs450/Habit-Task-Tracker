import 'package:habit_task_tracker/backend.dart';
import 'package:habit_task_tracker/log.dart';
import 'package:habit_task_tracker/notifier.dart' as notifier;
import 'package:duration/duration.dart';

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
  Frequency frequency;
  Log log;
  List<notifier.Notification> notifications;
  static final Map<String, Habit> _habitCache = {};

  factory Habit({
    required String id,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required bool isRecurring,
    bool? doNotRetrieveFromCache,
    Frequency? frequency,
    String? description,
  }) {
    if (_habitCache.containsKey(id) && doNotRetrieveFromCache != true) {
      return _habitCache[id]!;
    }
    final habit = Habit._internal(
      id: id,
      name: name,
      startDate: startDate,
      endDate: endDate,
      isRecurring: isRecurring,
      frequency: frequency ?? Frequency.none,
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
    required this.frequency,
    this.description,
    required this.notifications,
  }) : _id = id,
       log = createLog(id, description);

  String get gId => _id;

  String get gName => name;

  DateTime get gStartDate => startDate;

  DateTime get gEndDate => endDate;

  bool get gIsRecurring => isRecurring;

  Frequency get gFrequency => frequency;

  dynamic get gCompleted => _completed;

  Map<String, dynamic> toJson() {
    return {
      'id': _id,
      'name': name,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isRecurring': isRecurring,
      'frequency': gFrequency.toString(),
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
      frequency: frequencyMap[json['frequency']] ?? Frequency.none,
    )
    // Following line can be uncommented once
    // `withNotification()` is idempotent.
    // For now, behavior is unchanged
    // .withNotification()
    ;
  }

  static Habit? getById(String id) {
    try {
      // First search currently loaded habits
      return Habit.fromId(id);
    } catch (e) {
      // Then search database
      // Currently waiting on PR #43 to merge before implementing
      return null;
    }
  }

  // Schedule notification for a habit. Automatically
  // handles scheduling, recurrence, etc. This function
  // is not idempotent *yet*; that's a stretch goal.
  //
  // Intended to be used like this:
  //   final habit = Habit(...).withNotification();
  Habit withNotification({Duration offset = const Duration(hours: 1)}) {
    // Ensure that startDate is in the future
    // Might be smart to do this in the initializer
    final DateTime notifDateTime;
    if (startDate.subtract(offset).isBefore(DateTime.now())) {
      notifDateTime = DateTime.now()
          .add(offset)
          .add(const Duration(seconds: 1));
    } else {
      notifDateTime = startDate;
    }
    final notification = notifier.Notification(
      this,
      'Reminder for $name',
      'Don\'t forget to complete your habit!\nIt\'s due in ${offset.pretty(abbreviated: false)}.',
    );
    notifications.add(notification);
    // `Notification.showScheduled` handles recurrence automatically
    notification.showScheduled(notifDateTime, offset: offset);
    return this;
  }

  void complete() {
    //updateTimeStamps(DateTime.now());
  }
}

Future<void> saveHabit(Habit habit) async {
  await saveData('Habits', habit.gId, habit.toJson());
}

Future<Habit> loadHabit(String id) async {
  var data = await loadData('Habits', id);
  return Habit.fromJson(data);
}

Future<void> deleteHabit(String id) async {
  await deleteData('Habits', id);
}
