import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

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
