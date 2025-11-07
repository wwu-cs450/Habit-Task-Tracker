import 'package:habit_task_tracker/backend.dart';

class Log {
  final String _id;
  DateTime timestamp;
  String habitId;
  String? notes;

  Log({
    required String id,
    required this.timestamp,
    required this.habitId,
    this.notes,
  }) : _id = id;

  String get gId => _id;

  DateTime get gTimestamp => timestamp;

  String get gHabitId => habitId;

  String? get gNotes => notes;

  Map<String, dynamic> toJson() {
    return {
      'id': _id,
      'timestamp': timestamp.toIso8601String(),
      'habitId': habitId,
      'notes': notes,
    };
  }

  factory Log.fromJson(Map<String, dynamic> json) {
    return Log(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      habitId: json['habitId'],
      notes: json['notes'],
    );
  }
}

Future<int> saveLog(Log log) async {
  await saveData('Logs', log._id.toString(), log.toJson());
  return 0;
}

Future<Log> loadLog(String id) async {
  var data = await loadData('Logs', id);
  if (data == null) {
    throw Exception('Log with id $id not found');
  }
  return Log.fromJson(data);
}
