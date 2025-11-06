import 'package:habit_task_tracker/backend.dart';

enum Frequency { daily , weekly, monthly, yearly, none }

Map<String, Frequency> frequencyMap = {
  'Frequency.daily': Frequency.daily,
  'Frequency.weekly': Frequency.weekly,
  'Frequency.monthly': Frequency.monthly,
  'Frequency.yearly': Frequency.yearly,
  'Frequency.none': Frequency.none,
};

class Habit {
  final String _id;
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
}

int saveHabit(Habit habit) {
  saveData('Habits', habit._id, {
    'name': habit.name,
    'description': habit.description,
    'startDate': habit.startDate.toIso8601String(),
    'endDate': habit.endDate.toIso8601String(),
    'isRecurring': habit.isRecurring,
    'frequency': habit.gFrequency.toString(),
  });
  return 0;
}

Future<dynamic> loadHabit(String id) async {
  var data = await loadData('Habits', id);
  return Habit(
    id: id,
    name: data['name'],
    description: data['description'],
    startDate: DateTime.parse(data['startDate']),
    endDate: DateTime.parse(data['endDate']),
    isRecurring: data['isRecurring'],
    frequency: frequencyMap[data['frequency']] ?? Frequency.none,
  );
}
