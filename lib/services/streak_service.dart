import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_prayer_record.dart';

class StreakService {
  static const String _recordsKey = 'prayer_records';
  static const String _currentStreakKey = 'current_streak';
  static const String _bestStreakKey = 'best_streak';

  // ── In-memory cache ─────────────────────────────────────────────────────
  // Keeps the full records map in RAM after the first load.
  // All reads hit the cache; only writes go to disk.
  Map<DateTime, DailyPrayerRecord>? _memoryCache;
  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<Map<DateTime, DailyPrayerRecord>> getAllRecords() async {
    // Return cached data if available — avoids JSON decode on every call
    if (_memoryCache != null) return _memoryCache!;

    final prefs = await _getPrefs();
    final String? data = prefs.getString(_recordsKey);
    if (data == null) {
      _memoryCache = {};
      return _memoryCache!;
    }

    final decoded = json.decode(data);
    final Map<DateTime, DailyPrayerRecord> records = {};

    // If old List format, clear it and return empty
    if (decoded is List) {
      await prefs.remove(_recordsKey);
      _memoryCache = {};
      return _memoryCache!;
    } else if (decoded is Map<String, dynamic>) {
      decoded.forEach((key, value) {
        try {
          final record = DailyPrayerRecord.fromJson(value);
          records[DateTime(record.date.year, record.date.month, record.date.day)] = record;
        } catch (_) {}
      });
    }

    _memoryCache = records;
    return _memoryCache!;
  }

  Future<DailyPrayerRecord?> getRecordForDate(DateTime date) async {
    final records = await getAllRecords();
    final normalized = DateTime(date.year, date.month, date.day);
    return records[normalized];
  }

  Future<void> saveRecord(DailyPrayerRecord record) async {
    final prefs = await _getPrefs();
    // Ensure cache is loaded
    final records = await getAllRecords();
    final normalized = DateTime(record.date.year, record.date.month, record.date.day);
    records[normalized] = record;

    // Encode and write to disk (single write, no re-read)
    final Map<String, dynamic> jsonMap = {};
    records.forEach((date, rec) {
      jsonMap[date.toIso8601String()] = rec.toJson();
    });
    // Fire-and-forget the disk write — don't block the UI
    prefs.setString(_recordsKey, json.encode(jsonMap));

    // Update streak counts using the in-memory cache (no disk re-read)
    _updateStreakCountsFromCache(records, prefs);
  }

  /// Calculates streaks entirely from the in-memory cache.
  /// No disk reads needed — streaks are derived from the map we already have.
  void _updateStreakCountsFromCache(
      Map<DateTime, DailyPrayerRecord> records, SharedPreferences prefs) {
    final sortedDates = records.keys.toList()..sort((a, b) => a.compareTo(b));

    // Current streak: count backwards from today
    int currentStreak = 0;
    final now = DateTime.now();
    DateTime checkDate = DateTime(now.year, now.month, now.day);
    while (true) {
      final record = records[checkDate];
      if (record != null && record.allCompleted) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    // Best streak: scan forward through sorted dates
    int bestStreak = 0;
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

    // Fire-and-forget writes
    prefs.setInt(_currentStreakKey, currentStreak);
    prefs.setInt(_bestStreakKey, bestStreak);
  }

  Future<int> getCurrentStreak() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_currentStreakKey) ?? 0;
  }

  Future<int> getBestStreak() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_bestStreakKey) ?? 0;
  }
}