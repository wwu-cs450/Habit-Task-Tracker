import 'package:flutter/foundation.dart';
import 'package:habit_task_tracker/habit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class Notification {
  // Static fields
  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static const AndroidNotificationDetails _androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'habit_notifs', // Unique channel ID.
        'Habit Notifications', // Visible channel name.
        channelDescription: 'Reminders for tasks and habits',
        importance: Importance.max,
        priority: Priority.high,
        groupKey: 'habit_notifs', // Group notifications under this key
      );
  static const DarwinNotificationDetails _iosNotificationDetails =
      DarwinNotificationDetails(
        presentAlert: true, // Display an alert when notification is delivered
        presentBadge: true, // Update the app icon badge number
        presentSound: true, // Play a sound
        threadIdentifier:
            'habit_notifs', // Notifications are grouped under this ID
      );
  static const NotificationDetails notificationDetails = NotificationDetails(
    iOS: _iosNotificationDetails,
    android: _androidPlatformChannelSpecifics,
  );

  // Notification fields
  String habitId;
  String title;
  String body;

  factory Notification(Habit habit, String title, String body) {
    return Notification._internal(habit.gId, title, body);
  }

  Notification._internal(this.habitId, this.title, this.body);

  static Future<void> initialize(
    Function(NotificationResponse) onNotificationPressed,
  ) async {
    // Ensure Flutter bindings are initialized before using plugins.
    WidgetsFlutterBinding.ensureInitialized();

    // Android initialization settings.
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS (Darwin) initialization settings.
    const DarwinInitializationSettings
    initializationSettingsDarwin = DarwinInitializationSettings(
      // Optionally, add a callback to handle notifications while the app is in foreground.
      // onDidReceiveLocalNotification: (id, title, body, payload) async {
      //   // Handle iOS foreground notification.
      // },
    );

    // Combine both platform settings.
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    // Initialize the plugin with a callback for when a notification is tapped.
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onNotificationPressed,
    );

    // Request runtime permissions for notifications.
    // These permissions are also listed in the app manifest files
    final androidImpl = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl != null) {
      final enabled = await androidImpl.areNotificationsEnabled() ?? false;
      if (!enabled) {
        await androidImpl.requestNotificationsPermission();
      }
    }
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Configure the local timezone.
    await _configureLocalTimeZone();

    // Sends three test notifications for smoke testing purposes.
    // Run by adding `--dart-define=NOTIF_TEST=true` to `flutter run` command.
    await _maybeRunSmokeTest();
  }

  static Future<void> _maybeRunSmokeTest() async {
    const bool enabled = bool.fromEnvironment(
      'NOTIF_TEST',
      defaultValue: false,
    );
    if (!kDebugMode || !enabled) {
      return;
    }

    final now = DateTime.now();

    // Any habitId works; unknown IDs will be assumed to have `Frequency.none`.
    final n1 = Notification._internal(
      'debug-smoke-1',
      'Test Notification 1',
      'In 10s',
    );
    await n1.showScheduled(now.add(const Duration(seconds: 10)));
    final n2 = Notification._internal(
      'debug-smoke-2',
      'Test Notification 2',
      'In 20s',
    );
    await n2.showScheduled(now.add(const Duration(seconds: 20)));
    final n3 = Notification._internal(
      'debug-smoke-3',
      'Test Notification 3',
      'Immediate',
    );
    await n3.showImmediately();
  }

  static Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final timeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZone.identifier));
  }

  static Future<void> cancel(Habit habit) async {
    await flutterLocalNotificationsPlugin.cancel(habit.gId.hashCode);
  }

  Future<void> showImmediately({String? title, String? body}) async {
    // TZ needs to be initialized **first**
    await _configureLocalTimeZone();

    final String notifTitle = title ?? this.title;
    final String notifBody = body ?? this.body;
    await flutterLocalNotificationsPlugin.show(
      habitId.hashCode, // Unique ID for the notification.
      notifTitle, // Notification title.
      notifBody, // Notification body.
      notificationDetails, // Platform-specific details.
      payload: habitId, // Send habit ID as payload
    );
  }

  // Schedule notification at scheduledDate minus lead time
  Future<void> showScheduled(DateTime scheduledDate) async {
    // TZ needs to be initialized **first**
    await _configureLocalTimeZone();

    // Convert scheduledDate to TZDateTime
    final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );

    // Look up habit to get frequency
    final Habit? habit = Habit.fromId(habitId);
    final frequency = habit?.frequency ?? Frequency.none;

    // Determine the repeat interval based on frequency
    final DateTimeComponents? repeatInterval;
    switch (frequency) {
      case Frequency.daily:
        repeatInterval = DateTimeComponents.time;
        break;
      case Frequency.weekly:
        repeatInterval = DateTimeComponents.dayOfWeekAndTime;
        break;
      case Frequency.monthly:
        repeatInterval = DateTimeComponents.dayOfMonthAndTime;
        break;
      case Frequency.yearly:
        repeatInterval = DateTimeComponents.dateAndTime;
        break;
      case Frequency.none:
        repeatInterval = null; // Only schedule once
        break;
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      habitId.hashCode, // Unique ID for the notification.
      title, // Notification title.
      body, // Notification body.
      tzScheduledDate, // Scheduled time.
      notificationDetails, // Platform-specific details.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, //
      payload: habitId, // Send habit ID as payload
      matchDateTimeComponents: repeatInterval,
    );
  }
}
