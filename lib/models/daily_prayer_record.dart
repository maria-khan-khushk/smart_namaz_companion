class DailyPrayerRecord {
  final DateTime date;
  final Map<String, bool> prayersCompleted; // 'Fajr', 'Dhuhr', etc.
  bool get allCompleted => prayersCompleted.values.every((v) => v);
  int get completedCount => prayersCompleted.values.where((v) => v).length;

  DailyPrayerRecord({
    required this.date,
    required this.prayersCompleted,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'prayersCompleted': prayersCompleted,
  };

  factory DailyPrayerRecord.fromJson(Map<String, dynamic> json) => DailyPrayerRecord(
    date: DateTime.parse(json['date']),
    prayersCompleted: Map<String, bool>.from(json['prayersCompleted']),
  );
}