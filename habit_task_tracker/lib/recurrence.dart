import 'package:habit_task_tracker/habit.dart';

class Recurrence {
  Frequency freq;
  DateTime? interval = DateTime.now();
  Recurrence({required this.freq, this.interval});
}
