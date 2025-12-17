import 'dart:async';
import 'package:flutter/material.dart';
import 'package:habit_task_tracker/notifier.dart' as notifier;
import 'package:habit_task_tracker/recurrence.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'habit.dart';
import 'main_helpers.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'search.dart';
import 'calendar.dart';
import 'timer.dart';
import 'uuid.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';

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
        textTheme: GoogleFonts.interTextTheme(),
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
  // Cached copy of all habits loaded from the DB to avoid reloading every keystroke
  List<Habit> _allHabits = <Habit>[];
  // Debounce timer for search input
  Timer? _searchDebounce;
  // Track which habit IDs have a log timestamp for today.
  final Set<String> _completedToday = <String>{};
  // Cached set of completed IDs for the full habit list (used when searching)
  final Set<String> _allCompletedToday = <String>{};
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

  // TEMPORARY LOCAL SEARCH METHOD UNTIL search.dart IS FIXED
  void _localSearch(String value) async {
    final trimmedValue = value.trim();
    debugPrint('Search input: "$trimmedValue"');

    if (trimmedValue.isEmpty) {
      try {
        if (_allHabits.isEmpty) {
          final result = await loadHabitsFromDb();
          if (!mounted) return;
          final List<Habit> habits = (result['habits'] as List<dynamic>)
              .cast<Habit>();
          final Set<String> completed = (result['completedIds'] as Set<dynamic>)
              .cast<String>();
          _allHabits = List<Habit>.from(habits);
          setState(() {
            _habits = habits;
            _completedToday
              ..clear()
              ..addAll(completed);
            _allCompletedToday
              ..clear()
              ..addAll(completed);
            _expanded
              ..clear()
              ..addAll(List<bool>.filled(_habits.length, false));
          });
        } else {
          if (!mounted) return;
          setState(() {
            _habits = List<Habit>.from(_allHabits);
            _expanded
              ..clear()
              ..addAll(List<bool>.filled(_habits.length, false));
            // Restore the completed set from the cached full-set
            _completedToday
              ..clear()
              ..addAll(_allCompletedToday);
          });
        }
      } catch (e) {
        debugPrint('Search reload failed: $e');
      }
      return;
    }

    try {
      // Temporary in-memory search fallback while search.dart is being fixed
      List<Habit> allHabits;
      if (_allHabits.isNotEmpty) {
        allHabits = _allHabits;
      } else {
        final all = await loadHabitsFromDb();
        allHabits = (all['habits'] as List<dynamic>).cast<Habit>();
        _allHabits = List<Habit>.from(allHabits);
      }

      // Date formatting
      final lower = trimmedValue.toLowerCase();
      final startTokenMatch = RegExp(
        r'start:\s*(\d{4}-\d{2}-\d{2})',
        caseSensitive: false,
      ).firstMatch(lower);
      DateTime? startFilter;
      var textOnly = lower;
      if (startTokenMatch != null) {
        startFilter = DateTime.tryParse(startTokenMatch.group(1)!);
        textOnly = textOnly.replaceAll(startTokenMatch.group(0)!, '').trim();
      }

      // Date searching
      final bareDateMatch = RegExp(
        r"\b(\d{4}-\d{2}-\d{2})\b",
      ).firstMatch(textOnly);
      DateTime? bareDateFilter;
      if (bareDateMatch != null) {
        bareDateFilter = DateTime.tryParse(bareDateMatch.group(1)!);
        textOnly = textOnly.replaceAll(bareDateMatch.group(0)!, '').trim();
      }

      final q = textOnly;
      const int tempFuzzyVal = 70;
      final List<Habit> results = [];

      for (final h in allHabits) {
        final name = h.name.toLowerCase();
        final desc = (h.description ?? '').toLowerCase();

        // Date filtering
        if (startFilter != null) {
          if (!isSameDay(h.startDate, startFilter)) {
            continue;
          }
        }
        if (bareDateFilter != null) {
          final startMatches = isSameDay(h.startDate, bareDateFilter);
          final endMatches = isSameDay(h.endDate, bareDateFilter);
          if (!startMatches && !endMatches) {
            continue;
          }
        }
        if (q.isEmpty) {
          results.add(h);
          continue;
        }

        // Exact match or whole-word matching
        final pattern = RegExp(r'\b' + RegExp.escape(q) + r'\b');
        if (name == q || pattern.hasMatch(name) || pattern.hasMatch(desc)) {
          results.add(h);
          continue;
        }

        // Simple description checking
        if (desc.contains(q)) {
          results.add(h);
          continue;
        }

        // If the query contains numbers
        // require those numbers to match
        // exactly in the name/description. This
        // prevents fuzzy partial matches like "habit 1" matching
        // "habit 10".
        final digitRegex = RegExp(r'\b(\d+)\b');
        final digitMatches = digitRegex
            .allMatches(q)
            .map((m) => m.group(1)!)
            .toList();
        if (digitMatches.isNotEmpty) {
          final candidateDigits = <String>[];
          candidateDigits.addAll(
            digitRegex.allMatches(name).map((m) => m.group(1)!).toList(),
          );
          candidateDigits.addAll(
            digitRegex.allMatches(desc).map((m) => m.group(1)!).toList(),
          );

          bool allDigitsMatchAsPrefix = true;
          for (final d in digitMatches) {
            final found = candidateDigits.any((t) => t.startsWith(d));
            if (!found) {
              allDigitsMatchAsPrefix = false;
              break;
            }
          }
          if (!allDigitsMatchAsPrefix) {
            continue;
          }
        }

        // If no exact matches, do fuzzy matching
        final int nameScore = partialRatio(name, q);
        if (nameScore > tempFuzzyVal) {
          results.add(h);
          continue;
        }

        if (h.description != null) {
          final int descScore = partialRatio(desc, q);
          if (descScore > tempFuzzyVal) {
            results.add(h);
          }
        }
      }

      debugPrint(
        'Local search results for "$trimmedValue": ${results.length} habits found',
      );

      if (!mounted) return;

      final Set<String> completedMatches = results
          .where((h) => _allCompletedToday.contains(h.gId))
          .map((h) => h.gId)
          .toSet();

      setState(() {
        _habits = results;
        _expanded
          ..clear()
          ..addAll(List<bool>.filled(_habits.length, false));
        _completedToday
          ..clear()
          ..addAll(completedMatches);
      });
    } catch (e) {
      debugPrint('Search fallback failed: $e');
    }
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
      _localSearch(value);
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
      backgroundColor: Color(0xff060606),
      // Top App Bar (Header)
      appBar: AppBar(
        // Hamburger menu button to open navigation menu
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        backgroundColor: const Color(0xffd9d9d9),
        elevation: 0,
        // backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
            //Habits Header
            Text(
              "Habits",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: Color(0xffd9d9d9),
              ),
            ),
            SizedBox(height: 16),
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
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: progress),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) {
                            return LinearProgressIndicator(
                              value: value,
                              minHeight: 10,
                              backgroundColor: Colors.transparent,
                              valueColor: const AlwaysStoppedAnimation(
                                Color(0xff71c591),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(color: Colors.white),
                  ),
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
                        color: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                          side: const BorderSide(color: Color(0xffd9d9d9)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              // Checkbox to mark habit as done/not done
                              trailing: Transform.scale(
                                scale: 1.8,
                                child: Checkbox(
                                  value: _completedToday.contains(
                                    _habits[index].gId,
                                  ),
                                  shape: const CircleBorder(),
                                  side: const BorderSide(
                                    color: Color(0xffd9d9d9),
                                    width: 1,
                                  ),
                                  activeColor: const Color(0xff71c591),
                                  checkColor: Colors.black,
                                  onChanged: (bool? value) async {
                                    final newVal = value ?? false;
                                    final habit = _habits[index];

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

                                    final ok = await setCompletion(
                                      Uuid.fromString(habit.gId),
                                      newVal,
                                      habit.description,
                                    );

                                    if (!ok && mounted) {
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

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Failed to save state'),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),

                              // Set the title and subtitle (description) of the habit
                              title: Text(
                                _habits[index].name,
                                style: const TextStyle(
                                  color: Color(0xffd9d9d9),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                style: const TextStyle(
                                  color: Color(0xffd9d9d9),
                                ),
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
