import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/hadith_model.dart';

class HadithService {
  static List<HadithModel>? _allHadiths;
  static HadithModel? _cachedTodaysHadith;
  static int _cachedDayOfYear = -1;

  static Future<List<HadithModel>> loadHadiths() async {
    if (_allHadiths != null) return _allHadiths!;
    final String jsonString = await rootBundle.loadString('assets/hadiths.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    _allHadiths = jsonList.map((item) => HadithModel.fromJson(item)).toList();
    return _allHadiths!;
  }

  static Future<HadithModel> getTodaysHadith() async {
    final now = DateTime.now();
    final todayDayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;

    if (_cachedTodaysHadith != null && _cachedDayOfYear == todayDayOfYear) {
      return _cachedTodaysHadith!;
    }

    final hadiths = await loadHadiths();
    final index = todayDayOfYear % hadiths.length;
    _cachedTodaysHadith = hadiths[index];
    _cachedDayOfYear = todayDayOfYear;
    return _cachedTodaysHadith!;
  }

  static Future<void> preload() async {
    await loadHadiths();
    await getTodaysHadith();
  }
}