import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'habit.dart';
import 'calendar.dart';

class TimerPage extends StatefulWidget {
  final List<Habit> habits;
  const TimerPage({super.key, required this.habits});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text("Timer"),
        centerTitle: true,
      ),
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
              // Navigate to Habits Page
              ListTile(
                leading: const Icon(Icons.check_circle),
                title: const Text('Habits'),
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  Navigator.of(
                    context,
                  ).popUntil((route) => route.isFirst); // Go back to first page
                },
              ),
              // Navigate to Calendar Page
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Calendar'),
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  Navigator.of(
                    context,
                  ).popUntil((route) => route.isFirst); // Go back to first page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CalendarPage(habits: widget.habits),
                    ),
                  );
                },
              ),
              // Timer (current page)
              ListTile(
                leading: const Icon(Icons.timer),
                title: const Text('Timer'),
                selected: true,
                onTap: () {
                  Navigator.pop(context); // Just close drawer
                },
              ),
            ],
          ),
        ),
      ),
      body: const Center(child: TimerWidget()),
    );
  }
}

class TimerWidget extends StatefulWidget {
  const TimerWidget({super.key});

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  int _seconds = 0;
  int _minutes = 0;
  int _hours = 0;
  int _initialTotalSeconds = 0;
  Timer? _timer;
  bool _isRunning = false;

  void _startTimer() {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_hours == 0 && _minutes == 0 && _seconds == 0) {
        timer.cancel();
        if (!mounted) return;
        setState(() {
          _isRunning = false;
          _hours = _initialTotalSeconds ~/ 3600;
          _minutes = (_initialTotalSeconds % 3600) ~/ 60;
          _seconds = _initialTotalSeconds % 60;
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _seconds--;
        if (_seconds < 0) {
          _seconds = 59;
          _minutes--;
          if (_minutes < 0) {
            _minutes = 59;
            _hours--;
          }
        }
      });
    });
  }

  void _pauseTimer() {
    setState(() {
      _isRunning = false;
    });
    _timer?.cancel();
  }

  void _resetTimer() {
    setState(() {
      _isRunning = false;
      _seconds = _initialTotalSeconds % 60;
      _minutes = (_initialTotalSeconds % 3600) ~/ 60;
      _hours = _initialTotalSeconds ~/ 3600;
    });
    _timer?.cancel();
  }

  String _formatTime(int value) {
    return value.toString().padLeft(2, '0');
  }

  double get _progress {
    int totalSeconds = (_hours * 3600) + (_minutes * 60) + _seconds;
    if (_initialTotalSeconds == 0) return 0.0;
    return totalSeconds / _initialTotalSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // AI made the UI based on the design from Figma

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 280,
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Circular progress indicator
              SizedBox(
                width: 280,
                height: 280,
                child: CircularProgressIndicator(
                  value: _progress,
                  strokeWidth: 4,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                ),
              ),
              // Timer text with visual cue
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isRunning
                      ? null
                      : () async {
                          await showTimePickerDialog(
                            context,
                            _hours,
                            _minutes,
                            _seconds,
                            (hours, minutes, seconds) {
                              setState(() {
                                _hours = hours;
                                _minutes = minutes;
                                _seconds = seconds;
                                _initialTotalSeconds =
                                    (hours * 3600) + (minutes * 60) + seconds;
                              });
                            },
                          );
                        },
                  borderRadius: BorderRadius.circular(140),
                  child: Container(
                    width: 280,
                    height: 280,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${_formatTime(_hours)}:${_formatTime(_minutes)}:${_formatTime(_seconds)}",
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!_isRunning) ...[
                              Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Tap to set time",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 60),
        // Buttons row
        if (_initialTotalSeconds == 0)
          // Start button (when timer not set)
          ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text("Start", style: TextStyle(fontSize: 18)),
          )
        else if (!_isRunning &&
            _initialTotalSeconds ==
                ((_hours * 3600) + (_minutes * 60) + _seconds))
          // Start button (when timer is set but never started)
          ElevatedButton(
            onPressed: () {
              _startTimer();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text("Start", style: TextStyle(fontSize: 18)),
          )
        else
          // Control buttons (when timer has been started - running or paused)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pause/Resume toggle button
              Container(
                decoration: BoxDecoration(
                  color: _isRunning ? Colors.grey[700] : Colors.teal,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {
                    if (_isRunning) {
                      _pauseTimer();
                    } else {
                      _startTimer();
                    }
                  },
                  icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                  iconSize: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 20),
              // Reset button
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {
                    _resetTimer();
                  },
                  icon: const Icon(Icons.refresh),
                  iconSize: 32,
                  color: Colors.white,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

Future<void> showTimePickerDialog(
  BuildContext context,
  int initialHours,
  int initialMinutes,
  int initialSeconds,
  Function(int, int, int) onTimeChanged,
) async {
  Duration selectedDuration = Duration(
    hours: initialHours,
    minutes: initialMinutes,
    seconds: initialSeconds,
  );

  await showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          height: 300,
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const Text(
                      'Set Timer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        onTimeChanged(
                          selectedDuration.inHours,
                          selectedDuration.inMinutes % 60,
                          selectedDuration.inSeconds % 60,
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Cupertino Timer Picker
              Expanded(
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.hms,
                  initialTimerDuration: selectedDuration,
                  onTimerDurationChanged: (Duration duration) {
                    selectedDuration = duration;
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
