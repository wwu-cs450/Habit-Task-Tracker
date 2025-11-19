import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'habit.dart';

class CalendarPage extends StatefulWidget {
  final List<Habit> habits;
  const CalendarPage({super.key, required this.habits});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Habit Calendar")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            });

            // Show completed habits for the selected day
            final completed = <String>[];
            for (var habit in widget.habits) {
              if (habit.completedDates.any((d) => isSameDay(d, selected))) {
                completed.add(habit.name);
              }
            }

            if (completed.isNotEmpty) {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Completed Habits'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: completed.map((e) => Text(e)).toList(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            }
          },

          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
          },

          eventLoader: (day) {
            final events = <String>[];
            for (var habit in widget.habits) {
              if (habit.completedDates.any((d) => isSameDay(d, day))) {
                events.add(habit.name);
              }
            }
            return events;
          },
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (events.isNotEmpty) {
                return Positioned(
                  bottom: 4,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                    ),
                  ),
                );
              }
              return null;
            },
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          calendarStyle: const CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Colors.deepPurple,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
