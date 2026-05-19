import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/prayer_time_model.dart';

class PrefsHelper {
  static const String prayerTimesKey = "cached_prayer_times";
  static const String _cacheTimeKey = "cached_prayer_times_timestamp";

  // Singleton SharedPreferences instance — avoids creating a new one on every call.
  // SharedPreferences.getInstance() is itself cached by the plugin, but this
  // eliminates even the async overhead of the method call.
  static SharedPreferences? _prefs;
  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<void> cachePrayerTimes(PrayerTimeModel times) async {
    final prefs = await _getPrefs();
    final json = jsonEncode({
      'fajr': times.fajr, 'dhuhr': times.dhuhr, 'asr': times.asr,
      'maghrib': times.maghrib, 'isha': times.isha
    });
    prefs.setString(prayerTimesKey, json);
    prefs.setString(_cacheTimeKey, DateTime.now().toIso8601String());
  }

  static Future<PrayerTimeModel?> getCachedPrayerTimes() async {
    final prefs = await _getPrefs();
    final jsonString = prefs.getString(prayerTimesKey);
    if (jsonString == null) return null;

    // Check if cache is from today (prayer times change daily)
    final cacheTimeStr = prefs.getString(_cacheTimeKey);
    if (cacheTimeStr != null) {
      try {
        final cacheTime = DateTime.parse(cacheTimeStr);
        final now = DateTime.now();
        if (cacheTime.day != now.day || cacheTime.month != now.month || cacheTime.year != now.year) {
          // Cache is from a different day — still return it as fallback,
          // but the caller should fetch fresh times
        }
      } catch (_) {}
    }

    final map = jsonDecode(jsonString);
    return PrayerTimeModel(
      fajr: map['fajr'], dhuhr: map['dhuhr'], asr: map['asr'],
      maghrib: map['maghrib'], isha: map['isha'],
    );
  }
}