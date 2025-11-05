enum Frequency {
  daily,
  weekly,
  monthly,
  yearly,
}

class Habit {
  String id;
  String name;
  String description;
  // YYYY-MM-DD ex: [2024, 06, 12]
  List<int> startDate;
  List<int> endDate;
  bool isRecurring;
  Frequency? frequency;

  Habit({
    required this.id,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.isRecurring,
  });

}