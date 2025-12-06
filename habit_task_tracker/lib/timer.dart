import 'dart:async';
import 'package:flutter/material.dart';
import 'habit.dart';

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
      appBar: AppBar(title: const Text("Timer Page")),
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
  int _minutes = 30;
  int _hours = 0;
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
      _seconds = 0;
      _minutes = 30;
      _hours = 0;
    });
    _timer?.cancel();
  }

  String _formatTime(int value) {
    return value.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${_formatTime(_hours)}:${_formatTime(_minutes)}:${_formatTime(_seconds)}",
              style: TextStyle(fontSize: 80),
            ),
            MaterialButton(
              onPressed: () {
                _startTimer();
              },
              color: Colors.blue,
              child: Text(
                "S T A R T",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            MaterialButton(
              onPressed: () {
                _pauseTimer();
              },
              color: Colors.red,
              child: Text(
                "P A U S E",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            MaterialButton(
              onPressed: () {
                _resetTimer();
              },
              color: Colors.green,
              child: Text(
                "R E S E T",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
