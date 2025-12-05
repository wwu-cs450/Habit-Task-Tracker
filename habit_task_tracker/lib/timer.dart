import 'package:flutter/material.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

  class _TimerPageState extends State<TimerPage> {
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: const Text("Timer")),
        body: const Center(
          child: Text("Timer goes here"),
        ),
      );
    }
    int seconds = 0;
  bool isRunning = false;
  // Timer? timer;

//   void startTimer() {
//     isRunning = true;
//     timer = Timer.periodic(const Duration(seconds: 1), (_) {
//       setState(() {
//         seconds++;
//       });
//     });
//   }

//   void stopTimer() {
//     isRunning = false;
//     timer?.cancel();
//   }

//   void resetTimer() {
//     stopTimer();
//     setState(() {
//       seconds = 0;
//     });
//   }
}
