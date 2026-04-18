import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/prayer_time_model.dart';

class PrefsHelper {
  static const String prayerTimesKey = "cached_prayer_times";

  static Future<void> cachePrayerTimes(PrayerTimeModel times) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode({
      'fajr': times.fajr, 'dhuhr': times.dhuhr, 'asr': times.asr,
      'maghrib': times.maghrib, 'isha': times.isha
    });
    await prefs.setString(prayerTimesKey, json);
  }

  static Future<PrayerTimeModel?> getCachedPrayerTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(prayerTimesKey);
    if (jsonString == null) return null;
    final map = jsonDecode(jsonString);
    return PrayerTimeModel(
      fajr: map['fajr'], dhuhr: map['dhuhr'], asr: map['asr'],
      maghrib: map['maghrib'], isha: map['isha'],
    );
  }
}