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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
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
      body: Center(child: TimerWidget()),
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
  int _initialSeconds = 0;
  int _initialHours = 0;
  int _initialMinutes = 0;
  int _initialSecondsValue = 0;
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
        setState(() {
          _isRunning = false;
          _hours = _initialHours;
          _minutes = _initialMinutes;
          _seconds = _initialSecondsValue;
        });
        return;
      }
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
      _seconds = _initialSecondsValue;
      _minutes = _initialMinutes;
      _hours = _initialHours;
    });
    _timer?.cancel();
  }

  String _formatTime(int value) {
    return value.toString().padLeft(2, '0');
  }

  double get _progress {
    int totalSeconds = (_hours * 3600) + (_minutes * 60) + _seconds;
    if (_initialSeconds == 0) return 0.0;
    return totalSeconds / _initialSeconds;
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
                  value: _isRunning ? _progress : 0.0,
                  strokeWidth: 4,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                ),
              ),
              // Timer text with visual cue
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
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
                          _initialHours = hours;
                          _initialMinutes = minutes;
                          _initialSecondsValue = seconds;
                          _initialSeconds =
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
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit, size: 16, color: Colors.grey[600]),
                            SizedBox(width: 4),
                            Text(
                              "Tap to set time",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
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
        SizedBox(height: 60),
        // Buttons row
        if (!_isRunning)
          // Start button (when not running)
          ElevatedButton(
            onPressed: () {
              _startTimer();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text("Start", style: TextStyle(fontSize: 18)),
          )
        else
          // Control buttons (when running)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Play/Resume button (green)
              Container(
                decoration: BoxDecoration(
                  color: Colors.teal,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {
                    _startTimer();
                  },
                  icon: Icon(Icons.play_arrow),
                  iconSize: 32,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 20),
              // Pause button (grey)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {
                    _pauseTimer();
                  },
                  icon: Icon(Icons.pause),
                  iconSize: 32,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 20),
              // Reset button (grey)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {
                    _resetTimer();
                  },
                  icon: Icon(Icons.refresh),
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
