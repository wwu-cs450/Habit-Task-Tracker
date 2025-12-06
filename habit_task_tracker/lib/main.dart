import 'package:flutter/material.dart';
import 'package:habit_task_tracker/notifier.dart' as notifier;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:habit_task_tracker/timer.dart';
import 'habit.dart';
import 'main_helpers.dart';
import 'calendar.dart';
import 'uuid.dart';

// I got some help from GitHub CoPilot with this code. I also got some ideas from
// this youtube video: https://www.youtube.com/watch?v=K4P5DZ9TRns

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const MyApp app = MyApp();

  await notifier.Notification.initialize(MyApp.onNotificationPressed);

  runApp(app);
}

// Class to provide styling and information for the entire app
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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

  static void onNotificationPressed(NotificationResponse response) {
    // final String? payload = response.payload;
    // In future, highlight specific habit based on payload
    // print('Notification tapped for habit with id: $payload');
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
class _MyHomePageState extends State<MyHomePage> {
  // Create list to store habits
  List<Habit> _habits = <Habit>[];
  // Track which habit IDs have a log timestamp for today.
  final Set<String> _completedToday = <String>{};
  // Track which habit cards are expanded in the UI
  final List<bool> _expanded = <bool>[];

  double progress = 0.0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Load habits from the database and save it to the UI state
    loadHabitsFromDb()
        .then((result) {
          if (!mounted) return;
          final List<Habit> habits = (result['habits'] as List<dynamic>)
              .cast<Habit>();
          final Set<String> completed = (result['completedIds'] as Set<dynamic>)
              .cast<String>();
          setState(() {
            _habits = habits;
            _completedToday.clear();
            _completedToday.addAll(completed);
            _expanded.clear();
            for (var _ in _habits) {
              _expanded.add(false);
            }
          });
          _updateProgressBar(_habits.length, _completedToday.length);
        })
        .catchError((e) {
          debugPrint('Error loading habits: $e');
        });
  }

  // Method for updating the Progress Bar
  void _updateProgressBar(int total, int done) {
    final double p = total == 0 ? 0.0 : done / total;
    if (!mounted) return;
    setState(() {
      progress = p;
    });
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

              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Calendar'),
                onTap: () {
                  debugPrint('Calendar tapped');
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CalendarPage(habits: _habits),
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.timer),
                title: const Text('Timer'),
                onTap: () {
                  debugPrint('Timer tapped');
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TimerPage(habits: _habits),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),

      // Main Page
      body: Padding(
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
                      value: progress,
                      minHeight: 10,
                      // NEED TO DECIDE WHAT COLORS TO USE HERE
                      backgroundColor: Colors.grey.shade300,
                      color: Colors.greenAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${(progress * 100).round()}%'),
                ],
              ),
            ),

            // List of Habits
            Expanded(
              child: ListView.separated(
                itemCount: _habits.length,
                // Card spacing
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                // Cards
                itemBuilder: (context, index) {
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
                                value: _completedToday.contains(
                                  _habits[index].gId,
                                ),
                                // Change habit completion status
                                onChanged: (bool? value) async {
                                  final newVal = value ?? false;
                                  final habit = _habits[index];

                                  // Update UI state
                                  setState(() {
                                    if (newVal) {
                                      _completedToday.add(habit.gId);
                                    } else {
                                      _completedToday.remove(habit.gId);
                                    }
                                  });
                                  _updateProgressBar(
                                    _habits.length,
                                    _completedToday.length,
                                  );

                                  // Save the Change to the Database
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  final ok = await setCompletion(
                                    Uuid.fromString(habit.gId),
                                    newVal,
                                    habit.description,
                                  );

                                  if (!ok) {
                                    // rollback UI on failure
                                    if (!mounted) return;
                                    setState(() {
                                      if (newVal) {
                                        _completedToday.remove(habit.gId);
                                      } else {
                                        _completedToday.add(habit.gId);
                                      }
                                    });
                                    _updateProgressBar(
                                      _habits.length,
                                      _completedToday.length,
                                    );
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('Failed to save state'),
                                      ),
                                    );
                                  }
                                },
                              ),
                              // Set the title and subtitle (description) of the habit
                              title: Text(_habits[index].name),
                              subtitle: Text(
                                _habits[index].description ?? '',
                                maxLines: _expanded[index] ? null : 1,
                                overflow: _expanded[index]
                                    ? TextOverflow.visible
                                    : TextOverflow.ellipsis,
                              ),
                              // Expand/collapse the habit on tap
                              onTap: () {
                                setState(() {
                                  _expanded[index] = !_expanded[index];
                                });
                              },
                            ),
                            // Expanded content shown only when expanded
                            if (_expanded[index])
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                            'Start: ${_format(_habits[index].startDate)}',
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
                                            'End: ${_format(_habits[index].endDate)}',
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
                                            'Recurring: ${_habits[index].gIsRecurring ? frequencyToString(_habits[index].gFrequency) : "No"}',
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
                                                  'Edit ${_habits[index].name}',
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
                                            final habit = _habits[index];
                                            await deleteHabitWithConfirmation(
                                              context,
                                              habit,
                                              (id) async {
                                                if (!mounted) return;
                                                setState(() {
                                                  final idx = _habits
                                                      .indexWhere(
                                                        (h) => h.gId == id,
                                                      );
                                                  if (idx != -1) {
                                                    _habits.removeAt(idx);
                                                    _expanded.removeAt(idx);
                                                    _completedToday.remove(id);
                                                  }
                                                });
                                                _updateProgressBar(
                                                  _habits.length,
                                                  _completedToday.length,
                                                );
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
      ),
      // Plus button to add a new habit
      floatingActionButton: SizedBox(
        width: 80,
        height: 80,
        child: FloatingActionButton(
          onPressed: () async {
            await showCreateHabitDialog(context, (habit) async {
              if (!mounted) return;
              setState(() {
                _habits.insert(0, habit);
                _expanded.insert(0, false);
              });
              _updateProgressBar(_habits.length, _completedToday.length);
            });
          },
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 45),
        ),
      ),
    );
  }
}
