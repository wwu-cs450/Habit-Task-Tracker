import 'package:habit_task_tracker/backend.dart';
import 'package:habit_task_tracker/log.dart';

enum Frequency { daily, weekly, monthly, yearly, none }

Map<String, Frequency> frequencyMap = {
  'Frequency.daily': Frequency.daily,
  'Frequency.weekly': Frequency.weekly,
  'Frequency.monthly': Frequency.monthly,
  'Frequency.yearly': Frequency.yearly,
  'Frequency.none': Frequency.none,
};

class Habit {
  final String _id;
  dynamic _completed;
  String name;
  String? description;
  DateTime startDate;
  DateTime endDate;
  bool isRecurring;
  Frequency? frequency;

  Habit({
    required String id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.isRecurring,
    this.frequency,
    this.description,
  }) : _id = id;

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
    );
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
