import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_prayer_record.dart';

class StreakService {
  static const String _recordsKey = 'prayer_records';
  static const String _currentStreakKey = 'current_streak';
  static const String _bestStreakKey = 'best_streak';

  Future<Map<DateTime, DailyPrayerRecord>> getAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_recordsKey);
    if (data == null) return {};

    final decoded = json.decode(data);
    final Map<DateTime, DailyPrayerRecord> records = {};

    // If old List format, clear it and return empty
    if (decoded is List) {
      print("Old list format found. Clearing corrupted data.");
      await prefs.remove(_recordsKey);
      return {};
    }
    else if (decoded is Map<String, dynamic>) {
      decoded.forEach((key, value) {
        try {
          final record = DailyPrayerRecord.fromJson(value);
          records[DateTime(record.date.year, record.date.month, record.date.day)] = record;
        } catch (e) {
          print("Error parsing record: $e");
        }
      });
    }
    return records;
  }

  Future<DailyPrayerRecord?> getRecordForDate(DateTime date) async {
    final records = await getAllRecords();
    final normalized = DateTime(date.year, date.month, date.day);
    return records[normalized];
  }

  Future<void> saveRecord(DailyPrayerRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getAllRecords();  // This will now clear old List data
    final normalized = DateTime(record.date.year, record.date.month, record.date.day);
    records[normalized] = record;

    final Map<String, dynamic> jsonMap = {};
    records.forEach((date, rec) {
      jsonMap[date.toIso8601String()] = rec.toJson();
    });
    await prefs.setString(_recordsKey, json.encode(jsonMap));
    await _updateStreakCounts();
  }

  Future<void> _updateStreakCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getAllRecords();
    final sortedDates = records.keys.toList()..sort((a, b) => a.compareTo(b));

    int currentStreak = 0;
    int bestStreak = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime checkDate = today;
    while (true) {
      final record = records[checkDate];
      if (record != null && record.allCompleted) {
        currentStreak++;
        checkDate = checkDate.subtract(Duration(days: 1));
      } else {
        break;
      }
    }

    int tempStreak = 0;
    DateTime? prevDate;
    for (var date in sortedDates) {
      final record = records[date];
      if (record != null && record.allCompleted) {
        if (prevDate == null || date.difference(prevDate).inDays == 1) {
          tempStreak++;
        } else {
          tempStreak = 1;
        }
        if (tempStreak > bestStreak) bestStreak = tempStreak;
        prevDate = date;
      } else {
        tempStreak = 0;
        prevDate = null;
      }
    }

    await prefs.setInt(_currentStreakKey, currentStreak);
    await prefs.setInt(_bestStreakKey, bestStreak);
  }

  Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_currentStreakKey) ?? 0;
  }

  Future<int> getBestStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_bestStreakKey) ?? 0;
  }
}