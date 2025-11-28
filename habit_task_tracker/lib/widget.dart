// taken from https://ejolie.hashnode.dev/developing-ios-android-home-screen-widgets-in-flutter

import 'package:home_widget/home_widget.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
class WidgetService {
  /// iOS
  static const iOSWidgetAppGroupId = 'group.com.example.habitTaskTrackerGroup';
  // todo change name
  static const widgetiOSName = 'HabitWidget';

  /// Android
  static const androidPackagePrefix = 'com.example.habitTaskTracker';
  static const widgetAndroidName =
      '$androidPackagePrefix.receivers.WidgetReceiver';

  /// Called in main.dart
  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(iOSWidgetAppGroupId);
    await HomeWidget.registerInteractivityCallback(interactiveCallback);
  }

  /// Save data to Shared Preferences
  static Future<void> _saveData<T>(String key, T data) async {
    await HomeWidget.saveWidgetData<T>(key, data);
  }

  /// Retrieve data from Shared Preferences
  static Future<T?> _getData<T>(String key) async {
    return await HomeWidget.getWidgetData<T>(key);
  }

  /// Request to update widgets on both iOS and Android
  static Future<void> _updateWidget({
    String? iOSWidgetName,
    String? qualifiedAndroidName,
  }) async {
    final result = await HomeWidget.updateWidget(
      name: iOSWidgetName,
      iOSName: iOSWidgetName,
      qualifiedAndroidName: qualifiedAndroidName,
    );
    debugPrint(
      '[WidgetService.updateWidget] iOSWidgetName: $iOSWidgetName, qualifiedAndroidName: $qualifiedAndroidName, result: $result',
    );
  }

  static Future<void> _complete() async {
    debugPrint('[WidgetService.complete]');
  }

  static Future<void> _uncomplete() async {
    debugPrint('[WidgetService.uncomplete]');
  }

  @pragma('vm:entry-point')
  static Future<void> interactiveCallback(Uri? uri) async {
    // We check the host of the uri to determine which action should be triggered.
    debugPrint('[WidgetService.interactiveCallback] uri: $uri');
    if (uri?.host == 'complete') {
      await _complete();
    } else if (uri?.host == 'uncomplete') {
      await _uncomplete();
    }
  }
}
