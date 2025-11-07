import 'package:localstore/localstore.dart';

final db = Localstore.instance;

// SAMPLE FUNCTIONS FOR SAVING AND LOADING DATA
// Replace these with Habit/Task specific functions
//-----------------------------------------------------------------
Future<void> saveTask(String id, Map<String, dynamic> data) async {
  await db.collection('data/sample').doc(id).set(data);
}

Future<Map<String, dynamic>?> loadTask(String id) async {
  return await db.collection('data/sample').doc(id).get();
}

//-----------------------------------------------------------------

Future<void> saveData(String collection, String id, dynamic data) async {
  await db.collection('data/$collection').doc(id).set(data);
}

Future<dynamic> loadData(String collection, String id) async {
  return await db.collection('data/$collection').doc(id).get();
}