import 'dart:async';
import 'package:flutter/material.dart';
import 'package:habit_task_tracker/notifier.dart' as notifier;
import 'package:habit_task_tracker/recurrence.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'habit.dart';
import 'main_helpers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'search.dart';
import 'calendar.dart';
import 'timer.dart';
import 'uuid.dart';

// I got help from GitHub CoPilot with this code. I also got some ideas from
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 0, 0, 0),
        ),
        textTheme: GoogleFonts.merriweatherTextTheme(),
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
  // Cached copy of all habits loaded from the DB (used with searching to restore)
  List<Habit> _allHabits = <Habit>[];
  // Debounce timer for search input
  Timer? _searchDebounce;
  // Track which habit IDs have a log timestamp for today.
  final Set<String> _completedToday = <String>{};
  // Cached set of completed IDs for the full habit list (used with searching to restore)
  final Set<String> _allCompletedToday = <String>{};
  // Track which habit cards are expanded
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
            _allHabits = List<Habit>.from(habits);
            _completedToday.clear();
            _completedToday.addAll(completed);
            _allCompletedToday
              ..clear()
              ..addAll(completed);
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

  Future<void> _searchHabitsFromDb(String value) async {
    final trimmedValue = value.trim();
    try {
      List<Habit> results = [];

      if (trimmedValue.isEmpty) {
        // If empty, load today's habits
        final result = await loadHabitsFromDb();
        results = (result['habits'] as List<dynamic>).cast<Habit>();

        if (!mounted) return;

        final completed = (result['completedIds'] as Set<dynamic>)
            .cast<String>();

        setState(() {
          _habits = results;
          _allHabits = List<Habit>.from(results);
          _expanded
            ..clear()
            ..addAll(List<bool>.filled(_habits.length, false));
          _completedToday
            ..clear()
            ..addAll(completed);
          _allCompletedToday
            ..clear()
            ..addAll(completed);
        });
        _updateProgressBar(_habits.length, _completedToday.length);
        return;
      }

      // Search by name and description
      results = await _performTextSearch(trimmedValue);

      // Sort results by startDate (newest first) to match the original order
      results.sort((a, b) => b.startDate.compareTo(a.startDate));

      // Final deduplication check before displaying
      final finalResults = <Habit>[];
      final seenIds = <String>{};
      for (final habit in results) {
        if (!seenIds.contains(habit.gId)) {
          seenIds.add(habit.gId);
          finalResults.add(habit);
        }
      }

      if (!mounted) return;

      final Set<String> completedMatches = finalResults
          .where((h) => _allCompletedToday.contains(h.gId))
          .map((h) => h.gId)
          .toSet();

      setState(() {
        _habits = finalResults;
        _expanded
          ..clear()
          ..addAll(List<bool>.filled(_habits.length, false));
        _completedToday
          ..clear()
          ..addAll(completedMatches);
      });
    } catch (e) {
      debugPrint('searchHabits failed: $e');
    }
  }

  /// Helper method to search by name and description
  Future<List<Habit>> _performTextSearch(String query) async {
    // Try searching by name first
    final nameResults = await searchHabits(name: query);

    // Also search by description
    final descResults = await searchHabits(description: query);

    // Merge results, avoiding duplicates using gId
    final seenIds = <String>{};
    final results = <Habit>[];

    for (final habit in nameResults) {
      if (!seenIds.contains(habit.gId)) {
        seenIds.add(habit.gId);
        results.add(habit);
      }
    }

    for (final habit in descResults) {
      if (!seenIds.contains(habit.gId)) {
        seenIds.add(habit.gId);
        results.add(habit);
      }
    }

    return results;
  }

  // Method for updating the Progress Bar
  void _updateProgressBar(int total, int done) {
    final double p = total == 0 ? 0.0 : done / total;
    if (!mounted) return;
    setState(() {
      progress = p;
    });
  }

  // Debounced onChanged handler to avoid calling the search on every keystroke
  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _searchHabitsFromDb(value);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  // Format DateTime to Date string
  String _format(DateTime d) => d.toIso8601String().split('T').first;

  // Format recurrence details to string
  String _recurrenceText(List<Recurrence> recurrences) {
    if (recurrences.isEmpty) {
      return 'No';
    }
    // Get frequency strings
    return recurrences
        .map((f) => frequencyToString(f.freq))
        // Unique frequencies only
        .toSet()
        .toList()
        .join(', ');
  }

  // Main body build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      // Top App Bar (Header)
      appBar: AppBar(
        // Hamburger menu button to open navigation menu
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        backgroundColor: const Color.fromARGB(255, 221, 146, 181),
        // backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                leading: const Icon(Icons.timer),
                title: const Text('Timer'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TimerPage()),
                  );
                },
              ),
              // Navigate to Calendar Page
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Calendar'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CalendarPage(habits: _habits),
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
            // Search Bar
            SizedBox(
              height: 44,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search Habits',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.shade400,
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.shade400,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.shade600,
                      width: 2.0,
                    ),
                  ),
                ),
                // Handle searching
                onChanged: (value) {
                  _onSearchChanged(value);
                },
                style: const TextStyle(fontSize: 14),
              ),
            ),
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
                      color: const Color.fromARGB(255, 28, 164, 255),
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
                                      _allCompletedToday.add(habit.gId);
                                    } else {
                                      _completedToday.remove(habit.gId);
                                      _allCompletedToday.remove(habit.gId);
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
                                        _allCompletedToday.remove(habit.gId);
                                      } else {
                                        _completedToday.add(habit.gId);
                                        _allCompletedToday.add(habit.gId);
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
                                            'Recurring: ${_habits[index].gIsRecurring ? _recurrenceText(_habits[index].gRecurrences) : "No"}',
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
                                                    _allHabits.removeWhere(
                                                      (h) => h.gId == id,
                                                    );
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
                _allHabits.insert(0, habit);
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
