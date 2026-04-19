class DailyPrayerRecord {
  final DateTime date;
  final Map<String, bool> prayersCompleted;
  final int streak;

  DailyPrayerRecord({
    required this.date,
    required this.prayersCompleted,
    this.streak = 0,
  });

  int get completedCount => prayersCompleted.values.where((v) => v == true).length;
  bool get allCompleted => completedCount == 5;

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'prayersCompleted': prayersCompleted,
      'streak': streak,
    };
  }

  factory DailyPrayerRecord.fromJson(Map<String, dynamic> json) {
    return DailyPrayerRecord(
      date: DateTime.parse(json['date']),
      prayersCompleted: Map<String, bool>.from(json['prayersCompleted']),
      streak: json['streak'] ?? 0,
    );
  }
}