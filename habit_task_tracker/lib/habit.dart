import 'package:habit_task_tracker/backend.dart';

enum Frequency {
  daily,
  weekly,
  monthly,
  yearly,
}

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

  String get gFrequency => frequency != null ? frequency.toString() : 'None';
  


}

int saveHabit(Habit habit){
  // Placeholder for storing data logic
  saveData('Habits', habit._id, habit);
  return 0;
}