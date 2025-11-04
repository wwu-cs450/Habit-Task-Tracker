import 'package:flutter/material.dart';

// I got some help from GitHub CoPilot with this code. I also got some ideas from
// this youtube video: https://www.youtube.com/watch?v=K4P5DZ9TRns

void main() {
  runApp(const MyApp());
}

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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  // Temporarily start with two habits
  final List<bool> _checked = List<bool>.filled(2, false, growable: true);
  final List<bool> _expanded = List<bool>.filled(2, false, growable: true);
  // THIS SHOULD SWITCH TO WORKING WITH A CLASS AND DB BUT TWO LISTS IS TEMPORARY SOLUTION
  final List<String> _titles = List<String>.filled(2, 'Title', growable: true);
  final List<String> _descriptions = List<String>.filled(
    2,
    'Description',
    growable: true,
  );

  // Create habit method
  void createHabit(String title, String description) {
    setState(() {
      _checked.add(false);
      _expanded.add(false);
      _titles.add(title);
      _descriptions.add(description);
    });
  }

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
      setState(() {
        _checked.removeAt(index);
        _expanded.removeAt(index);
        // Keep title/description lists in sync
        if (index >= 0 && index < _titles.length) {
          _titles.removeAt(index);
        }
        if (index >= 0 && index < _descriptions.length) {
          _descriptions.removeAt(index);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // compute progress for the progress bar
    int total = _checked.length;
    int done = _checked.where((v) => v).length;
    double progress = total == 0 ? 0.0 : done / total;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
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
                      // Need to decide what colors to use here
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
                itemCount: _checked.length,
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
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              // Checkbox to mark habit as done/not done
                              leading: Checkbox(
                                value: _checked[index],
                                onChanged: (bool? value) {
                                  setState(() {
                                    // Update the habit status
                                    _checked[index] = value ?? false;
                                  });
                                },
                              ),
                              // Set the title and subtitle of the habit
                              title: Text(_titles[index]),
                              subtitle: Text(
                                _descriptions[index],
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
                                    // Edit button
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      tooltip: 'Edit',
                                      onPressed: () {
                                        // Make this edit the habit visually and in the database
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Edit ${index + 1}'),
                                          ),
                                        );
                                      },
                                    ),
                                    // Delete button
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
            // Make this take information from user and store in the database
            createHabit('New Habit', 'Description');
          },
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 45),
        ),
      ),
    );
  }
}
