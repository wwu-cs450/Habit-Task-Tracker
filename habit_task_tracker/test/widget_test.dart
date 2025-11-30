// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habit_task_tracker/main.dart';
import '_setup_mocks.dart';

void main() {
  setUpAll(setupMocks);

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

    // Tap the ListTile for the habit that was just added (ensures onTap fires).
    final titleFinder = find.text('Test Habit');
    expect(titleFinder, findsOneWidget);

    // Find the Card that contains the habit and tap its ListTile to expand.
    final cardFinder = find.byType(Card);
    expect(cardFinder, findsOneWidget);
    final listTileInCard = find.descendant(
      of: cardFinder,
      matching: find.byType(ListTile),
    );

    if (listTileInCard.evaluate().isNotEmpty) {
      await tester.tap(listTileInCard);
    } else {
      await tester.tap(titleFinder);
    }
    // Allow more time for AnimatedSize and other UI transitions.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Click the delete button. Expand the card if necessary
    final deleteFinder = find.widgetWithIcon(IconButton, Icons.delete);
    if (deleteFinder.evaluate().isEmpty) {
      if (listTileInCard.evaluate().isNotEmpty)
        await tester.tap(listTileInCard);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }

    if (deleteFinder.evaluate().isEmpty) {
      fail('Delete button not found after expanding card');
    }

    await tester.ensureVisible(deleteFinder);
    expect(deleteFinder, findsOneWidget);
    await tester.tap(deleteFinder);
    await tester.pumpAndSettle();

    // Confirm deletion in a dialog that appears
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Ensure the card was deleted
    expect(find.byType(Card), findsNothing);
  });
}
