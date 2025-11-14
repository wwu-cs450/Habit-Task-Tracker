import 'package:flutter_test/flutter_test.dart';
import 'package:habit_task_tracker/search.dart';

void main() {
  group('Habit Search Test', () {
    List results = searchHabits(
      name: 'Exercise',
    )
  });
}
