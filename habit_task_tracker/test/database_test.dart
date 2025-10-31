import 'package:flutter_test/flutter_test.dart';
import 'package:habit_task_tracker/backend.dart';


// sample test to verify saving and loading data from the localstore database
// delete this test when backend is functional
void main() {
  group('Database Sample Test', () {
    test('Save and Load Task', () async {
      String taskId = 'test_task_1';
      Map<String, dynamic> taskData = {
        'title': 'Test Task',
        'completed': false,
      };

      // Save the task
      await saveTask(taskId, taskData);

      // Load the task
      Map<String, dynamic>? loadedData = await loadTask(taskId);

      // Verify the loaded data matches the saved data
      expect(loadedData, isNotNull);
      expect(loadedData!['title'], equals('Test Task'));
      expect(loadedData['completed'], equals(false));
    });
  });
}