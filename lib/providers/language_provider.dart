import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = Locale('en');

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Locale get locale => _locale;
  bool get isUrdu => _locale.languageCode == 'ur';

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('language');
    if (saved != null) {
      _locale = Locale(saved);
      notifyListeners();
    }
  }

  void setLanguage(String languageCode) async {
    _locale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
    notifyListeners();
  }
}