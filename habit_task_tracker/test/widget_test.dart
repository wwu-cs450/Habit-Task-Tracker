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

    // Test adding habits

    // Ensure there are 0 habits initially
    expect(find.byType(Card), findsNWidgets(0));

    // Open the dialog for adding a new habit
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Populate the fields in the dialog
    await tester.enterText(find.byType(TextField).at(0), 'Test Habit');
    await tester.enterText(find.byType(TextField).at(1), 'Test description');

    // Save the habit
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Ensure that the card was added
    expect(find.byType(Card), findsNWidgets(1));

    // Test deleting habits

    // Tap the card for the habit that was just added
    await tester.tap(find.text('Test Habit'));
    await tester.pumpAndSettle();

    // Click the delete button
    final deleteFinder = find.widgetWithIcon(IconButton, Icons.delete).first;
    await tester.tap(deleteFinder);
    await tester.pumpAndSettle();

    // Confirm deletion in a dialog that appears
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Ensure the card was deleted
    expect(find.byType(Card), findsNothing);
  });
}
