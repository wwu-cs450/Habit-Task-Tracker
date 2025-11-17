import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'habit.dart';
import 'backend.dart';
import 'log.dart';
import 'main_helpers.dart';

// I got some help from GitHub CoPilot with this code. I also got some ideas from
// this youtube video: https://www.youtube.com/watch?v=K4P5DZ9TRns

void main() {
  runApp(const MyApp());
}

// Class to provide styling and information for the entire app
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
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
class _MyHomePageState extends State<MyHomePage> {
  // Create list to store habits
  List<Habit> _habits = <Habit>[];
  // Track which habit IDs have a log timestamp for today.
  final Set<String> _completedToday = <String>{};
  final List<bool> _expanded = <bool>[];

  double progress = 0.0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Load habits via helper and apply to UI state
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

  // Main body build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
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
              // NEEDS TO BE UPDATED TO LINK TO DASHBOARD PAGE
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Dashboard'),
                onTap: () {
                  debugPrint('Dashboard tapped');
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle),
                title: const Text('Habits'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              // NEEDS TO BE UPDATED TO LINK TO CALENDAR PAGE
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Calendar'),
                onTap: () {
                  debugPrint('Calendar tapped');
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
                                // Modify habit completion status
                                onChanged: (bool? value) async {
                                  final newVal = value ?? false;
                                  final habit = _habits[index];
                                  setState(() {
                                    if (newVal) {
                                      _completedToday.add(habit.gId);
                                      try {
                                        habit.complete();
                                      } catch (_) {}
                                    } else {
                                      _completedToday.remove(habit.gId);
                                    }
                                  });

                                  // Update the progress bar after changes
                                  _updateProgressBar(
                                    _habits.length,
                                    _completedToday.length,
                                  );

                                  // Save the habit status
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  try {
                                    // Update logs for today's completion
                                    final now = DateTime.now();
                                    if (newVal) {
                                      try {
                                        final existingLog = await loadLog(
                                          habit.gId,
                                        );
                                        // Check if a log with today's timestamp exists
                                        final exists = existingLog.gTimeStamps
                                            .any(
                                              (dt) =>
                                                  dt.year == now.year &&
                                                  dt.month == now.month &&
                                                  dt.day == now.day,
                                            );
                                        // Only add timestamp if it doesn't already exist
                                        if (!exists) {
                                          existingLog.timeStamps.add(now);
                                          await saveLog(existingLog);
                                        }
                                      } catch (_) {
                                        // no existing log, create one and add timestamp
                                        final l = createLog(
                                          habit.gId,
                                          habit.description,
                                        );
                                        await l.updateTimeStamps(now);
                                      }
                                    } else {
                                      try {
                                        final existingLog = await loadLog(
                                          habit.gId,
                                        );
                                        existingLog.timeStamps.removeWhere(
                                          (dt) =>
                                              dt.year == now.year &&
                                              dt.month == now.month &&
                                              dt.day == now.day,
                                        );
                                        if (existingLog.timeStamps.isEmpty) {
                                          await deleteData('Logs', habit.gId);
                                        } else {
                                          await saveLog(existingLog);
                                        }
                                      } catch (_) {
                                        debugPrint(
                                          "No log to remove timestamp from",
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    // revert UI state on failure
                                    if (!mounted) return;
                                    setState(() {
                                      if (newVal) {
                                        _completedToday.remove(habit.gId);
                                      } else {
                                        _completedToday.add(habit.gId);
                                      }
                                    });
                                    // Update progress bar after reverting the change
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
                                child: Row(
                                  children: [
                                    // Habit Edit Button
                                    // EDITING STILL NEEDS TO BE IMPLEMENTED. SHOULD PROBABLY BE IN HABIT CLASS
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
                                              final idx = _habits.indexWhere(
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
