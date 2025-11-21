import 'package:flutter/material.dart';

enum OptFrequency { daily, weekly, monthly, yearly, none }

class Frequency {
  OptFrequency freq;
  DateTime? interval = DateTime.now();
  List<DateTime>? intervals = [DateTime.now()];
  Frequency({required this.freq, this.interval, this.intervals});
}
