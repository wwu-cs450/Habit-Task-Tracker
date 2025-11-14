import 'package:habit_task_tracker/backend.dart';
import 'package:habit_task_tracker/habit.dart';

class Log {
  final String _habitId;
  List<DateTime> timeStamps = [];
  String? notes;


  Log({
    required String habitId,
    List<DateTime>? timeStamps,
    this.notes,
  })  : _habitId = habitId,
        timeStamps = timeStamps ?? [];


  String get gId => _habitId;

  List<DateTime> get gTimeStamps => timeStamps;

  String? get gNotes => notes;


  Map<String, dynamic> toJson() {
    return {
      'habitId': _habitId,
      'timestamps': timeStamps.map((dt) => dt.toIso8601String()).toList(),
      'notes': notes,
    };
  }


  factory Log.fromJson(Map<String, dynamic> json) {
    return Log(
      habitId: json['habitId'],
      timeStamps: (json['timestamps'] as List<dynamic>)
          .map((e) => DateTime.parse(e as String))
          .toList(),
      notes: json['notes'],
    );
  }


  Future<void> updateTimeStamps(DateTime newTimeStamps) async {
    timeStamps.add(newTimeStamps);
    await saveLog(this);
  }

  Future<void> updateNotes(String newNotes) async {
    notes = newNotes;
    await saveLog(this);
  }


  int getCompletionPercentage(Frequency frequency, DateTime startDate) {
    final now = DateTime.now();
    int totalOpportunities = 0;

    switch (frequency) {
      case Frequency.daily:
        totalOpportunities = now.difference(startDate).inDays + 1;
        break;
      case Frequency.weekly:
        totalOpportunities =
            ((now.difference(startDate).inDays) / 7).floor() + 1;
        break;
      case Frequency.monthly:
        totalOpportunities =
            (now.year - startDate.year) * 12 + (now.month - startDate.month) + 1;
        break;
      case Frequency.yearly:
        totalOpportunities = now.year - startDate.year + 1;
        break;
      default:
        totalOpportunities = 1;
    }

    if (totalOpportunities <= 0) return 0;
    
    return ((timeStamps.length / totalOpportunities) * 100).round();
  }
}

Future<void> saveLog(Log log) async {
  await saveData('Logs', log.gId, log.toJson());
}


Future<Log> loadLog(String id) async {
  var data = await loadData('Logs', id);
  if (data == null) {
    throw Exception('Log with id $id not found');
  }
  return Log.fromJson(data);
}
