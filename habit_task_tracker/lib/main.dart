import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'habit.dart';
import 'backend.dart';
import 'calendar.dart';

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
class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  // Create lists to store habits and their UI state
  // THIS WILL BE HANDLED IN THE HABIT CLASS BY STORING LOGS
  List<Habit> _habits = <Habit>[];
  final List<bool> _checked = <bool>[];
  final List<bool> _expanded = <bool>[];

  double progress = 0.0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  // Load habits from the database (currently localstore)
  Future<void> _loadHabits() async {
    try {
      final Map<String, dynamic>? all = await db
          .collection('data/Habits')
          .get();
      final List<Habit> list = <Habit>[];
      final List<bool> loadedCompleted = <bool>[];
      if (all != null) {
        all.forEach((key, value) {
          try {
            final Map<String, dynamic> map = Map<String, dynamic>.from(value);
            list.add(Habit.fromJson(map));
            loadedCompleted.add(map['completed'] == true);
          } catch (e) {
            debugPrint('Failed to parse habit $key: $e');
          }
        });
      }

      // Match habits with their completed status, then sort them so newest is first
      final List<MapEntry<Habit, bool>> paired = <MapEntry<Habit, bool>>[];
      for (var i = 0; i < list.length; i++) {
        paired.add(
          MapEntry(
            list[i],
            i < loadedCompleted.length ? loadedCompleted[i] : false,
          ),
        );
      }
      paired.sort((a, b) => b.key.startDate.compareTo(a.key.startDate));

      setState(() {
        _habits = paired.map((e) => e.key).toList();
        _checked.clear();
        for (var e in paired) {
          _checked.add(e.value);
        }
        _expanded.clear();
        for (var _ in _habits) {
          _expanded.add(false);
        }
      });
      // Update progress after loading
      _updateProgressBar(_habits.length, _checked.where((v) => v).length);
    } catch (e) {
      debugPrint('Error loading habits: $e');
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

  // THIS SHOULD PROBABLY BE HANDLED IN THE HABIT CLASS AND USED HERE
  // Create habit method
  Future<void> createHabit(String title, String description) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final habit = Habit(
      id: id,
      name: title,
      description: description,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 1)),
      isRecurring: false,
    );

    setState(() {
      _habits.insert(0, habit);
      _checked.insert(0, false);
      _expanded.insert(0, false);
    });
    // Update progress after adding
    _updateProgressBar(_habits.length, _checked.where((v) => v).length);

    try {
      final Map<String, dynamic> m = habit.toJson();
      m['completed'] = false;
      await db.collection('data/Habits').doc(id).set(m);
    } catch (e) {
      debugPrint('Failed to save habit: $e');
    }
  }

  // THIS SHOULD PROBABLY BE HANDLED IN THE HABIT CLASS AND USED HERE
  // Delete habit method
  Future<void> deleteHabit(int index) async {
    if (index < 0 || index >= _checked.length) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete item?'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final habit = _habits[index];
      setState(() {
        _habits.removeAt(index);
        _checked.removeAt(index);
        _expanded.removeAt(index);
      });

      // Update progress after deletion
      _updateProgressBar(_habits.length, _checked.where((v) => v).length);

      // Remove from the database (currently localstore)
      try {
        await db.collection('data/Habits').doc(habit.gId).delete();
      } catch (e) {
        debugPrint('Failed to delete habit ${habit.gId}: $e');
      }
    }
  }

  // Show dialog to create a new habit with title and description fields
  Future<void> _showCreateHabitDialog() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: const Text('New Habit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                autofocus: false,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                keyboardType: TextInputType.multiline,
                minLines: 1,
                maxLines: 3,
                textAlignVertical: TextAlignVertical.top,
              ),
            ],
          ),
        ),
        actions: [
          // Cancel button
          TextButton(
            onPressed: () async {
              // Unfocus and hide keyboard before closing dialog
              final navigator = Navigator.of(context, rootNavigator: true);
              FocusManager.instance.primaryFocus?.unfocus();
              try {
                await SystemChannels.textInput.invokeMethod('TextInput.hide');
              } catch (_) {}
              await Future.delayed(const Duration(milliseconds: 150));
              navigator.pop(false);
            },
            child: const Text('Cancel'),
          ),
          // Save button
          TextButton(
            onPressed: () async {
              // Unfocus and hide keyboard before closing dialog
              final navigator = Navigator.of(context, rootNavigator: true);
              FocusManager.instance.primaryFocus?.unfocus();
              try {
                await SystemChannels.textInput.invokeMethod('TextInput.hide');
              } catch (_) {}
              await Future.delayed(const Duration(milliseconds: 150));
              navigator.pop(true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true) {
      final title = titleController.text.isEmpty
          ? 'New Habit'
          : titleController.text.trim();
      final desc = descController.text.trim();
      createHabit(title, desc.isEmpty ? 'Description' : desc);
    }

    titleController.dispose();
    descController.dispose();
  }

  // MAIN BODY BUILD METHOD
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

              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Calendar'),
                onTap: () {
                      debugPrint('Calendar tapped');
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CalendarPage(habits: _habits)),
                  );
                },
              ),
            ],
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  // Progress Bar
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
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
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
                                value: _checked[index],
                                onChanged: (bool? value) async {
                                  final newVal = value ?? false;
                                  setState(() {
                                    _checked[index] = newVal;
                                    // Optionally update habit internal state
                                    if (newVal) {
                                      try {
                                        _checked[index] = true;
                                        _habits[index].complete();
                                      } catch (_) {}
                                    }
                                  });

                                  // Update the progress bar after changes
                                  _updateProgressBar(
                                    _habits.length,
                                    _checked.where((v) => v).length,
                                  );

                                  // Save the habit status
                                  final habit = _habits[index];
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  try {
                                    final Map<String, dynamic> m = habit
                                        .toJson();
                                    m['completed'] = newVal;
                                    await db
                                        .collection('data/Habits')
                                        .doc(habit.gId)
                                        .set(m);
                                    // Handle issues and revert changes on failure
                                  } catch (e) {
                                    // revert UI state on failure
                                    if (!mounted) return;
                                    setState(() {
                                      _checked[index] = !newVal;
                                    });
                                    // Update progress bar after reverting the change
                                    _updateProgressBar(
                                      _habits.length,
                                      _checked.where((v) => v).length,
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
                                      onPressed: () {
                                        deleteHabit(index);
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
          onPressed: () {
            // Open dialog to get title and details for the habit.
            // NEED TO GET MORE HABIT DETAILS SUCH AS START/END DATE, RECURRING, ETC.
            _showCreateHabitDialog();
          },
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 45),
        ),
      ),
    );
  }
}
