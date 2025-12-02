import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'dart:io';

class MockFlutterLocalNotificationsPlugin extends Mock
    with
        // MockPlatformInterfaceMixin is a mixin and must be used with `with`, not `implements`.
        MockPlatformInterfaceMixin // ignore: prefer_mixin
    implements FlutterLocalNotificationsPlatform {}

void setupMocks() {
  // Set up notifier mock
  TestWidgetsFlutterBinding.ensureInitialized();
  final MockFlutterLocalNotificationsPlugin mock =
      MockFlutterLocalNotificationsPlugin();
  FlutterLocalNotificationsPlatform.instance = mock;
}

void clearTestHabitsFolder() async {
  final path = Directory('data/Habits_test');
  if (await path.exists()) {
    final files = path.listSync();
    for (var file in files) {
      if (file is File) {
        await file.delete();
      }
    }
  }
}
