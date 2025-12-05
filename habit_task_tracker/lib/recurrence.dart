import 'package:habit_task_tracker/habit.dart';

class Recurrence {
  Frequency freq;
  DateTime startDate;
  Recurrence({required this.freq, DateTime? startDate})
    : startDate = startDate ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {'freq': freq.toString(), 'startDate': startDate.toIso8601String()};
  }

  factory Recurrence.fromJson(Map<String, dynamic> json) {
    return Recurrence(
      freq: frequencyMap[json['freq']] ?? Frequency.none,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
    );
  }
}
