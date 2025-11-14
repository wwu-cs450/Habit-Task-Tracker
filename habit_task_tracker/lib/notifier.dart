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
  int habitId;
  String title;
  String body;

  factory Notification(Habit habit, String title, String body) {
    return Notification._internal(habit.gId.hashCode, title, body);
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

    // Configure the local timezone.
    _configureLocalTimeZone();

    // Test notification
    final testHabit = Habit(
      id: 'test_habit',
      name: 'Test Habit',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
      isRecurring: true,
    );
    final notification = Notification(
      testHabit,
      'Time to work on your habit!',
      'Keep up the good work with your habit: ${testHabit.gName}',
    );
    await notification.showImmediately();
  }

  static Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final timeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZone.identifier));
  }

  Future<void> showImmediately() async {
    flutterLocalNotificationsPlugin.show(
      habitId, // Unique ID for the notification.
      title, // Notification title.
      body, // Notification body.
      notificationDetails, // Platform-specific details.
      payload: habitId.toString(), // Send habit ID as payload
    );
  }

  Future<void> showScheduled(DateTime scheduledDate) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      habitId, // Unique ID for the notification.
      title, // Notification title.
      body, // Notification body.
      tz.TZDateTime.from(scheduledDate, tz.local), // Scheduled time.
      notificationDetails, // Platform-specific details.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, //
      payload: habitId.toString(), // Send habit ID as payload
    );
  }
}
