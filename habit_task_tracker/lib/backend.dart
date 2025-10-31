import 'package:localstore/localstore.dart';

final db = Localstore.instance;

// SAMPLE FUNCTIONS FOR SAVING AND LOADING DATA
// Replace these with Habit/Task specific functions
//-----------------------------------------------------------------
Future<void> saveTask(String id, Map<String, dynamic> data) async {
  await db.collection('sample').doc(id).set(data);
}

Future<Map<String, dynamic>?> loadTask(String id) async {
  return await db.collection('sample').doc(id).get();
}
//-----------------------------------------------------------------
