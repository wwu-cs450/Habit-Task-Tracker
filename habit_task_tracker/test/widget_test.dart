// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habit_task_tracker/main.dart';

void main() {
  testWidgets('Adding a habit with the FAB increases the card count', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // The app starts with two habit cards (per the initial lists)
    expect(find.byType(Card), findsNWidgets(0));

    // Tap the '+' icon and trigger a frame to add a new habit.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle(); // wait for the dialog to appear

    await tester.enterText(find.byType(TextField).at(0), 'Test Habit');
    await tester.enterText(find.byType(TextField).at(1), 'Test description');

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Verify that a new card was added.
    expect(find.byType(Card), findsNWidgets(1));
  });
}
