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

  group('Database Test for program storing', () {
    test('Save data directly to collection and load it back', () async {
      String collection = 'test_collection';
      String dataId = 'test_data_1';
      Map<String, dynamic> data = {
        "parameter1": "value1",
        "parameter2": 2,
        "parameter3": true,
        "parameter4": null,
        "parameter5": [1, 2, 3],
        "parameter6": {"nestedKey": "nestedValue"},
        };

      // Save the data
      await saveData(collection, dataId, data);

      // Load the data
      dynamic loadedData = await loadData(collection, dataId);

      // Verify the loaded data matches the saved data
      expect(loadedData, isNotNull);
      expect(loadedData['parameter1'], equals('value1'));
      expect(loadedData['parameter2'], equals(2));
      expect(loadedData['parameter3'], equals(true));
      expect(loadedData['parameter4'], equals(null));
      expect(loadedData['parameter5'], equals([1, 2, 3]));
      expect(loadedData['parameter6']['nestedKey'], equals('nestedValue'));

    });
  });

}
