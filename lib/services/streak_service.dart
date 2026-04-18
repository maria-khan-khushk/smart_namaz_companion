import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_prayer_record.dart';


class StreakService {
  static const String _storageKey = 'prayer_records';

  Future<void> saveRecord(DailyPrayerRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final allRecords = await getAllRecords();
    // Remove existing record for same date if any
    allRecords.removeWhere((r) => r.date.year == record.date.year && r.date.month == record.date.month && r.date.day == record.date.day);
    allRecords.add(record);
    final jsonList = allRecords.map((r) => r.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  Future<List<DailyPrayerRecord>> getAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => DailyPrayerRecord.fromJson(json)).toList();
  }

  Future<DailyPrayerRecord?> getRecordForDate(DateTime date) async {
    final all = await getAllRecords();
    try {
      return all.firstWhere((r) => r.date.year == date.year && r.date.month == date.month && r.date.day == date.day);
    } catch (e) {
      return null;
    }
  }

  // Get current streak (consecutive days where all prayers completed)
  Future<int> getCurrentStreak() async {
    final records = await getAllRecords();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int streak = 0;
    DateTime day = today;
    while (true) {
      final record = records.firstWhere(
        (r) => r.date.year == day.year && r.date.month == day.month && r.date.day == day.day,
        orElse: () => DailyPrayerRecord(date: day, prayersCompleted: {}),
      );
      if (record.allCompleted) {
        streak++;
        day = day.subtract(Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  // Mark a prayer as completed for today
  Future<void> markPrayerCompleted(String prayerName) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var record = await getRecordForDate(today);
    if (record == null) {
      final initialPrayers = {
        'Fajr': false,
        'Dhuhr': false,
        'Asr': false,
        'Maghrib': false,
        'Isha': false,
      };
      initialPrayers[prayerName] = true;
      record = DailyPrayerRecord(date: today, prayersCompleted: initialPrayers);
    } else {
      record.prayersCompleted[prayerName] = true;
    }
    await saveRecord(record);
  }
}