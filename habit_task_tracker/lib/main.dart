import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_task_tracker/notifier.dart' as notifier;
import 'main_helpers.dart';
import 'calendar.dart';
import 'state/habit_state.dart';

// I got some help from GitHub CoPilot with this code. I also got some ideas from
// this youtube video: https://www.youtube.com/watch?v=K4P5DZ9TRns

// Global navigator key for accessing context from notification handlers
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification handler with state-aware callback
  await notifier.Notification.initialize((response) {
    final habitId = response.payload;
    if (habitId != null) {
      // Get the state and toggle completion when notification is pressed
      final context = navigatorKey.currentContext;
      if (context != null) {
        context.read<HabitState>().toggleCompletion(habitId, true);
      }
    }
  });

  runApp(
    ChangeNotifierProvider(
      create: (_) => HabitState()..loadHabits(),
      child: const MyApp(),
    ),
  );
}

// Class to provide styling and information for the entire app
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Habit Task Tracker',
      theme: ThemeData(
        // Need to decide what color scheme to use
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 0, 0, 0),
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Habits'),
    );
  }
}

// Class to hold title and state for the home page
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// Main state class for the home page
class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  // Track which habit cards are expanded in the UI
  final Map<String, bool> _expanded = {};
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint('AppLifecycleState: $state');

    // Refresh habits when app comes to foreground to pick up any changes
    if (state == AppLifecycleState.resumed) {
      context.read<HabitState>().refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Format DateTime to Date string
  String _format(DateTime d) => d.toIso8601String().split('T').first;

  // Main body build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      // Top App Bar (Header)
      appBar: AppBar(
        // Hamburger menu button to open navigation menu
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),

      // Navigation Menu
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.6,
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Header with close button
              Container(
                height: 56,
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                // Close button in the header
                child: Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
              // Navigate to Habit Page
              ListTile(
                leading: const Icon(Icons.check_circle),
                title: const Text('Habits'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              Consumer<HabitState>(
                builder: (context, habitState, child) {
                  return ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Calendar'),
                    onTap: () {
                      debugPrint('Calendar tapped');
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CalendarPage(habits: habitState.habits),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),

      // Main Page
      body: Consumer<HabitState>(
        builder: (context, habitState, child) {
          if (habitState.isLoading && habitState.habits.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (habitState.error != null && habitState.habits.isEmpty) {
            return Center(child: Text('Error: ${habitState.error}'));
          }

          // Ensure expanded map has entries for all habits
          for (final habit in habitState.habits) {
            _expanded.putIfAbsent(habit.gId, () => false);
          }
          // Remove entries for habits that no longer exist
          _expanded.removeWhere(
            (id, _) => !habitState.habits.any((h) => h.gId == id),
          );

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: habitState.progress,
                          minHeight: 10,
                          // NEED TO DECIDE WHAT COLORS TO USE HERE
                          backgroundColor: Colors.grey.shade300,
                          color: Colors.greenAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('${(habitState.progress * 100).round()}%'),
                    ],
                  ),
                ),

                // List of Habits
                Expanded(
                  child: ListView.separated(
                    itemCount: habitState.habits.length,
                    // Card spacing
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    // Cards
                    itemBuilder: (context, index) {
                      final habit = habitState.habits[index];
                      final isCompleted = habitState.completedToday.contains(
                        habit.gId,
                      );
                      final isExpanded = _expanded[habit.gId] ?? false;

                      return ClipRect(
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  // Checkbox to mark habit as done/not done
                                  leading: Checkbox(
                                    value: isCompleted,
                                    // Change habit completion status
                                    onChanged: (bool? value) async {
                                      final newVal = value ?? false;
                                      final success = await habitState
                                          .toggleCompletion(habit.gId, newVal);

                                      if (!success && mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Failed to save state',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  // Set the title and subtitle (description) of the habit
                                  title: Text(habit.name),
                                  subtitle: Text(
                                    habit.description ?? '',
                                    maxLines: isExpanded ? null : 1,
                                    overflow: isExpanded
                                        ? TextOverflow.visible
                                        : TextOverflow.ellipsis,
                                  ),
                                  // Expand/collapse the habit on tap
                                  onTap: () {
                                    setState(() {
                                      _expanded[habit.gId] = !isExpanded;
                                    });
                                  },
                                ),
                                // Expanded content shown only when expanded
                                if (isExpanded)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      8,
                                      16,
                                      12,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Start Date
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_today,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                'Start: ${_format(habit.startDate)}',
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        // End Date
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_today,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                'End: ${_format(habit.endDate)}',
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        // Recurring Status
                                        Row(
                                          children: [
                                            const Icon(Icons.repeat, size: 14),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                'Recurring: ${habit.gIsRecurring ? frequencyToString(habit.gFrequency) : "No"}',
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Edit/Delete Buttons
                                        Row(
                                          children: [
                                            // Habit Edit Button
                                            IconButton(
                                              icon: const Icon(Icons.edit),
                                              tooltip: 'Edit',
                                              onPressed: () {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Edit ${habit.name}',
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            // Habit Delete Button
                                            IconButton(
                                              icon: const Icon(Icons.delete),
                                              tooltip: 'Delete',
                                              onPressed: () async {
                                                await deleteHabitWithConfirmation(
                                                  context,
                                                  habit,
                                                  (id) async {
                                                    await habitState
                                                        .removeHabit(id);
                                                  },
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      // Plus button to add a new habit
      floatingActionButton: Consumer<HabitState>(
        builder: (context, habitState, child) {
          return SizedBox(
            width: 80,
            height: 80,
            child: FloatingActionButton(
              onPressed: () async {
                await showCreateHabitDialog(context, (habit) async {
                  await habitState.addHabit(habit);
                });
              },
              shape: const CircleBorder(),
              child: const Icon(Icons.add, size: 45),
            ),
          );
        },
      ),
    );
  }
}
