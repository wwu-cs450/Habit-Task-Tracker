import 'package:habit_task_tracker/backend.dart';
import 'package:habit_task_tracker/log.dart';
import 'package:table_calendar/table_calendar.dart';

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
  Frequency? frequency;
  Log log;
  List<DateTime> completedDates;

  Habit({
    required String id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.isRecurring,
    this.frequency,
    this.description,
    List<DateTime>? completedDates, // optional in constructor
  }) : _id = id,
       log = createLog(id, description),
       completedDates = completedDates ?? [];

  String get gId => _id;

  String get gName => name;

  DateTime get gStartDate => startDate;

  DateTime get gEndDate => endDate;

  bool get gIsRecurring => isRecurring;

  Frequency get gFrequency => frequency ?? Frequency.none;

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
      frequency: frequencyMap[json['frequency']] ?? Frequency.none,
      completedDates: (json['completedDates'] as List<dynamic>?)
          ?.map((e) => DateTime.parse(e))
          .toList(),
    );
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

Future<Habit> loadHabit(String id) async {
  var data = await loadData('Habits', id);
  return Habit.fromJson(data);
}

Future<void> deleteHabit(String id) async {
  await deleteData('Habits', id);
}
